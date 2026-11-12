-- Comuni italiani e luogo dei canali (0.8.0, parte 1: schema).
--
-- Il luogo di un canale non è più un testo libero: si sceglie un comune da
-- un elenco ufficiale (ISTAT, 7.896 comuni, caricati dalle migrazioni
-- `20261116100100`..`20261116100400`). Il collegamento è una chiave esterna
-- facoltativa, quindi il database stesso rifiuta un comune che non esiste. Un
-- canale può non avere luogo (per esempio un'università online).
--
-- Nuovo:
--   municipalities                        elenco dei comuni (sola lettura per i client)
--   search_municipalities(query, limit)   suggerimenti mentre si scrive, senza
--                                         distinguere maiuscole e accenti
--   municipality_regions()                le regioni
--   municipality_provinces(region)        le province (di una regione, o tutte)
--   channels.municipality_id              il comune del canale (facoltativo)
--
-- `channels.place` resta, ma è il testo da mostrare ("Pisa (PI)") e lo calcola
-- un trigger dal comune; `province_code` e `region_name` sono copie per filtrare
-- senza join. Finché l'app non è aggiornata, un client può ancora scrivere
-- `place` a mano (nessun comune): la migrazione che chiude i permessi di
-- scrittura su `place` arriva insieme all'app.
--
-- Funzioni di servizio, riusate dalla ricerca di testo (`immutable_unaccent`,
-- `escape_like`).

-- ============================================================
-- Funzioni di servizio
-- ============================================================

create extension if not exists unaccent with schema extensions;

-- `unaccent` è "stable": per usarla negli indici serve un involucro immutabile.
create or replace function public.immutable_unaccent(p_text text)
returns text
language sql
immutable
parallel safe
strict
set search_path = ''
as $$
  select extensions.unaccent('extensions.unaccent'::regdictionary, p_text);
$$;

-- Rende innocui `\`, `%` e `_` dentro un pattern di `like`/`ilike`.
create or replace function public.escape_like(p_text text)
returns text
language sql
immutable
parallel safe
strict
set search_path = ''
as $$
  select replace(replace(replace(p_text, '\', '\\'), '%', '\%'), '_', '\_');
$$;

-- ============================================================
-- Comuni
-- ============================================================

create table public.municipalities (
  istat_code text not null,
  name text not null,
  province_code text not null,
  province_name text not null,
  region_name text not null,
  constraint municipalities_pkey primary key (istat_code),
  constraint municipalities_code_check check (istat_code ~ '^[0-9]{6}$'),
  constraint municipalities_province_code_check check (province_code ~ '^[A-Z]{2}$')
);

create index municipalities_province_idx on public.municipalities (province_code);
create index municipalities_region_idx on public.municipalities (region_name);

-- Dati di riferimento pubblici: leggibili da tutti, scrivibili solo con una
-- migrazione.
alter table public.municipalities enable row level security;
create policy "Municipalities readable by everyone" on public.municipalities
  for select to anon, authenticated using (true);
revoke all on public.municipalities from anon, authenticated;
grant select on public.municipalities to anon, authenticated;

-- ============================================================
-- Ricerca e elenchi
-- ============================================================

-- Comuni il cui nome contiene il testo, prima quelli che iniziano così, poi in
-- ordine alfabetico. Non distingue maiuscole e accenti ("forli" trova "Forlì").
-- Il nome non basta a distinguere gli omonimi: si mostra con la sigla.
create or replace function public.search_municipalities(
  p_query text,
  p_limit int default 10
)
returns table (
  istat_code text,
  name text,
  province_code text,
  province_name text,
  region_name text
)
language sql
stable
set search_path = ''
as $$
  select m.istat_code, m.name, m.province_code, m.province_name, m.region_name
  from public.municipalities m
  where btrim(coalesce(p_query, '')) <> ''
    and public.immutable_unaccent(lower(m.name))
        like '%' || public.escape_like(public.immutable_unaccent(lower(btrim(p_query)))) || '%'
  order by
    (public.immutable_unaccent(lower(m.name))
      like public.escape_like(public.immutable_unaccent(lower(btrim(p_query)))) || '%') desc,
    m.name,
    m.province_code
  limit least(greatest(p_limit, 1), 25);
$$;

create or replace function public.municipality_regions()
returns table (region_name text)
language sql
stable
set search_path = ''
as $$
  select distinct m.region_name from public.municipalities m order by 1;
$$;

-- Le province di una regione (o tutte, se `p_region` è nullo).
create or replace function public.municipality_provinces(p_region text default null)
returns table (province_code text, province_name text, region_name text)
language sql
stable
set search_path = ''
as $$
  select distinct m.province_code, m.province_name, m.region_name
  from public.municipalities m
  where p_region is null or m.region_name = p_region
  order by 2;
$$;

-- ============================================================
-- Collegamento con i canali
-- ============================================================

alter table public.channels
  add column municipality_id text references public.municipalities (istat_code),
  add column province_code text,
  add column region_name text;

create index channels_municipality_idx on public.channels (municipality_id);
create index channels_province_idx on public.channels (province_code);
create index channels_region_idx on public.channels (region_name);

-- Il testo da mostrare e le copie per filtrare dipendono sempre dal comune: i
-- client non li decidono. Senza comune (insert) `place` resta com'è, finché
-- esiste il vecchio testo libero; se il comune viene tolto, spariscono tutti.
create or replace function public.channels_sync_municipality()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_municipality record;
begin
  if new.municipality_id is not null then
    select m.name, m.province_code, m.region_name
    into v_municipality
    from public.municipalities m
    where m.istat_code = new.municipality_id;

    -- Comune inesistente: ci pensa la chiave esterna (23503), subito dopo.
    if not found then
      return new;
    end if;

    new.place := v_municipality.name || ' (' || v_municipality.province_code || ')';
    new.province_code := v_municipality.province_code;
    new.region_name := v_municipality.region_name;
  elsif tg_op = 'UPDATE' then
    new.place := null;
    new.province_code := null;
    new.region_name := null;
  end if;
  return new;
end;
$$;

create trigger channels_sync_municipality
  before insert or update of municipality_id on public.channels
  for each row execute function public.channels_sync_municipality();

-- I client leggono le nuove colonne (come le altre, una per una: `owner_id`
-- resta nascosto).
grant select (municipality_id, province_code, region_name)
  on public.channels to anon, authenticated;

-- ============================================================
-- Permessi
-- ============================================================

revoke execute on function public.search_municipalities(text, int) from public, anon;
revoke execute on function public.municipality_regions() from public, anon;
revoke execute on function public.municipality_provinces(text) from public, anon;

grant execute on function public.search_municipalities(text, int) to authenticated;
grant execute on function public.municipality_regions() to authenticated;
grant execute on function public.municipality_provinces(text) to authenticated;
