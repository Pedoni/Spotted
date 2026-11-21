-- La città di un canale diventa obbligatoria (#82).
--
-- Vale per i canali **nuovi** e per quelli **modificati**: un canale solo
-- online deve comunque indicare una città (per esempio la sede). I canali che
-- esistono già senza città restano come sono, finché il proprietario non li
-- modifica: l'app lo invita ad aggiungerla.
--
-- Perché non un vincolo `check (municipality_id is not null) not valid`:
-- Postgres controlla anche un vincolo non convalidato a ogni `update` della
-- riga, quindi `set_channel_image` (che aggiorna foto e copertina) farebbe
-- fallire i canali vecchi senza città. Il controllo sta invece dove serve:
--   * un trigger sull'insert (i client scrivono i canali con un insert
--     diretto, per le sole colonne concesse);
--   * `update_channel`, l'unico modo di modificare nome, argomento e comune.
-- Quando nessun canale sarà più senza città, si potrà aggiungere
-- `alter column municipality_id set not null` (e togliere il trigger).
--
-- Una città mancante dà `23514` (`ValidationFailure`). Il comune scelto deve
-- comunque esistere: lo garantisce già la chiave esterna.

create function public.channels_require_municipality()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.municipality_id is null or btrim(new.municipality_id) = '' then
    raise exception 'municipality is required' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger channels_require_municipality
  before insert on public.channels
  for each row execute function public.channels_require_municipality();

-- Come prima (stessa firma e stesse colonne), con la città obbligatoria.
create or replace function public.update_channel(
  p_channel_id uuid,
  p_name text,
  p_description text,
  p_topic_id uuid,
  p_municipality_id text
)
returns table (
  id uuid,
  topic_id uuid,
  name text,
  slug text,
  description text,
  place text,
  municipality_id text,
  province_code text,
  region_name text,
  avatar_path text,
  cover_path text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_name text := btrim(coalesce(p_name, ''));
  v_description text := nullif(btrim(coalesce(p_description, '')), '');
begin
  if not public.is_channel_owner(p_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if char_length(v_name) < 3 or char_length(v_name) > 60 then
    raise exception 'invalid channel name' using errcode = '23514';
  end if;
  if v_description is not null and char_length(v_description) > 500 then
    raise exception 'channel description too long' using errcode = '23514';
  end if;
  if p_municipality_id is null or btrim(p_municipality_id) = '' then
    raise exception 'municipality is required' using errcode = '23514';
  end if;

  update public.channels c
  set name = v_name,
      description = v_description,
      topic_id = p_topic_id,
      municipality_id = p_municipality_id
  where c.id = p_channel_id;

  return query
  select c.id, c.topic_id, c.name, c.slug, c.description, c.place,
         c.municipality_id, c.province_code, c.region_name,
         c.avatar_path, c.cover_path, c.created_at
  from public.channels c
  where c.id = p_channel_id;
end;
$$;

revoke execute on function public.update_channel(uuid, text, text, uuid, text)
  from public, anon;
grant execute on function public.update_channel(uuid, text, text, uuid, text)
  to authenticated;
