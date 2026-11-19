-- Approvazione degli spot e tag (0.10.0).
--
-- Uno spot non esce subito: lo scrive un utente, resta `pending` (in attesa) e
-- il proprietario del canale lo pubblica scegliendo da 1 a 3 tag oppure lo
-- rifiuta (`rejected`). Gli spot già pubblicati restano pubblicati, senza tag.
--
-- Stati: published | hidden | removed (come prima) | pending | rejected.
-- Il valore di default di `status` diventa `pending`: i client non scrivono
-- `status` (grant per colonna sull'insert), quindi ogni spot nuovo parte in
-- attesa.
--
-- Funzioni nuove (security definer, solo `authenticated`; per chi non è
-- proprietario del canale rispondono `42501`):
--   approve_spot(spot, tags)                    pending -> published con i tag;
--                                               `23514` se i tag non valgono,
--                                               `false` se non è in attesa
--   reject_spot(spot)                           pending -> rejected
--   publish_owner_spot(canale, titolo, testo, tag)
--                                               il proprietario pubblica subito
--   channel_pending_spots_page(canale, limite, offset)
--                                               la coda, dal più vecchio
--   channel_pending_spots_count(canale)         quanti spot aspettano
--   all_tags()                                  tutti i tag, con il nome visibile
--   channel_tags(canale)                        i tag scelti per quel canale
--                                               (generici + quelli del suo
--                                               argomento)
--
-- Funzioni modificate: `channel_spots_page`, `spot_detail`, `my_spots_page`,
-- `followed_spots_page` e `channel_moderation_spots_page` restituiscono anche
-- `tags` (vanno ricreate: cambia il tipo restituito); `spot_detail` fa vedere
-- gli spot in attesa o rifiutati al proprietario e all'autore; `my_spots_page`
-- include anche quelli; `set_spot_status` non tocca più gli spot in attesa o
-- rifiutati (si passa solo da `approve_spot` e `reject_spot`).
--
-- Policy nuova: "Authors read their own spots" (serve al `returning` dell'insert
-- di uno spot, che nasce `pending`).
--
-- Anonimato: nessuna colonna con id di utenti. I tag sono scelti dal
-- proprietario e non rivelano l'autore.

-- ============================================================
-- Stati
-- ============================================================

alter table public.spots drop constraint spots_status_check;
alter table public.spots
  add constraint spots_status_check
    check (status = any (array[
      'published', 'hidden', 'removed', 'pending', 'rejected'
    ]));
alter table public.spots alter column status set default 'pending';

-- L'insert dei client chiede indietro la riga appena scritta (`returning`), e
-- per farlo la riga deve passare anche le policy di lettura. Uno spot nuovo è
-- `pending`, e "Read published spots" lascia leggere solo i pubblicati: senza
-- questa policy ogni invio fallirebbe con `42501`. Ognuno legge i propri spot
-- (con le sole colonne concesse: `author_id` e `tags` restano chiusi).
create policy "Authors read their own spots" on public.spots
  for select to authenticated
  using (author_id = (select auth.uid()));

-- Coda del proprietario: spot in attesa di un canale.
create index spots_pending_idx
  on public.spots using btree (channel_id, created_at)
  where status = 'pending';

-- ============================================================
-- Tag: elenco fisso, scritto solo da migrazione
-- ============================================================

create table public.tags (
  slug text not null,
  label text not null,
  category text not null,
  -- Argomento a cui appartiene; nullo = generico (tutti i canali).
  topic_id uuid null,
  sort_order int not null,
  constraint tags_pkey primary key (slug),
  constraint tags_topic_id_fkey
    foreign key (topic_id) references public.topics (id) on delete cascade,
  constraint tags_slug_check check (slug ~ '^[a-z0-9]+$')
);

alter table public.tags enable row level security;
revoke all on table public.tags from anon, authenticated;

alter table public.spots
  add column tags text[] not null default '{}',
  add constraint spots_tags_check check (cardinality(tags) <= 3);

-- Generici (tutti i canali).
insert into public.tags (slug, label, category, sort_order) values
  ('crush', 'Crush', 'Generici', 1),
  ('cercasi', 'Cercasi', 'Generici', 2),
  ('trovato', 'Trovato', 'Generici', 3),
  ('perso', 'Perso', 'Generici', 4),
  ('complimenti', 'Complimenti', 'Generici', 5),
  ('confessione', 'Confessione', 'Generici', 6),
  ('domanda', 'Domanda', 'Generici', 7),
  ('consiglio', 'Consiglio', 'Generici', 8),
  ('sfogo', 'Sfogo', 'Generici', 9),
  ('meme', 'Meme', 'Generici', 10),
  ('curiosita', 'Curiosità', 'Generici', 11),
  ('ringraziamenti', 'Ringraziamenti', 'Generici', 12),
  ('avviso', 'Avviso', 'Generici', 13),
  ('annuncio', 'Annuncio', 'Generici', 14),
  ('animali', 'Animali', 'Generici', 15);

-- Università (si aggiungono ai generici).
insert into public.tags (slug, label, category, topic_id, sort_order)
select v.slug, v.label, v.category, t.id, v.sort_order
from (values
  ('esami', 'Esami', 'Didattica e studio', 101),
  ('lezioni', 'Lezioni', 'Didattica e studio', 102),
  ('professori', 'Professori', 'Didattica e studio', 103),
  ('appunti', 'Appunti', 'Didattica e studio', 104),
  ('dispense', 'Dispense', 'Didattica e studio', 105),
  ('ripetizioni', 'Ripetizioni', 'Didattica e studio', 106),
  ('gruppostudio', 'Gruppo studio', 'Didattica e studio', 107),
  ('esercitazioni', 'Esercitazioni', 'Didattica e studio', 108),
  ('laboratorio', 'Laboratorio', 'Didattica e studio', 109),
  ('tesi', 'Tesi', 'Didattica e studio', 110),
  ('tirocinio', 'Tirocinio', 'Didattica e studio', 111),
  ('sessione', 'Sessione', 'Didattica e studio', 112),
  ('voti', 'Voti', 'Didattica e studio', 113),
  ('orari', 'Orari', 'Didattica e studio', 114),
  ('frequenza', 'Frequenza', 'Didattica e studio', 115),
  ('aule', 'Aule', 'Spazi e servizi', 116),
  ('biblioteca', 'Biblioteca', 'Spazi e servizi', 117),
  ('salastudio', 'Sala studio', 'Spazi e servizi', 118),
  ('mensa', 'Mensa', 'Spazi e servizi', 119),
  ('bar', 'Bar', 'Spazi e servizi', 120),
  ('segreteria', 'Segreteria', 'Spazi e servizi', 121),
  ('wifi', 'Wi-Fi', 'Spazi e servizi', 122),
  ('stampanti', 'Stampanti', 'Spazi e servizi', 123),
  ('distributori', 'Distributori', 'Spazi e servizi', 124),
  ('iscrizione', 'Iscrizione', 'Burocrazia', 125),
  ('tasse', 'Tasse', 'Burocrazia', 126),
  ('isee', 'ISEE', 'Burocrazia', 127),
  ('borsadistudio', 'Borsa di studio', 'Burocrazia', 128),
  ('pianodistudi', 'Piano di studi', 'Burocrazia', 129),
  ('trasferimento', 'Trasferimento', 'Burocrazia', 130),
  ('certificati', 'Certificati', 'Burocrazia', 131),
  ('affitti', 'Affitti', 'Casa e città', 132),
  ('cercocasa', 'Cerco casa', 'Casa e città', 133),
  ('offrostanza', 'Offro stanza', 'Casa e città', 134),
  ('coinquilini', 'Coinquilini', 'Casa e città', 135),
  ('studentato', 'Studentato', 'Casa e città', 136),
  ('bus', 'Bus', 'Casa e città', 137),
  ('treno', 'Treno', 'Casa e città', 138),
  ('pendolari', 'Pendolari', 'Casa e città', 139),
  ('parcheggio', 'Parcheggio', 'Casa e città', 140),
  ('bici', 'Bici', 'Casa e città', 141),
  ('matricole', 'Matricole', 'Vita universitaria', 142),
  ('fuorisede', 'Fuorisede', 'Vita universitaria', 143),
  ('fuoricorso', 'Fuoricorso', 'Vita universitaria', 144),
  ('erasmus', 'Erasmus', 'Vita universitaria', 145),
  ('associazioni', 'Associazioni', 'Vita universitaria', 146),
  ('eventi', 'Eventi', 'Vita universitaria', 147),
  ('serata', 'Serata', 'Vita universitaria', 148),
  ('aperitivo', 'Aperitivo', 'Vita universitaria', 149),
  ('sport', 'Sport', 'Vita universitaria', 150),
  ('cercocompagnia', 'Cerco compagnia', 'Vita universitaria', 151),
  ('laurea', 'Laurea', 'Dopo la laurea', 152),
  ('magistrale', 'Magistrale', 'Dopo la laurea', 153),
  ('dottorato', 'Dottorato', 'Dopo la laurea', 154),
  ('stage', 'Stage', 'Dopo la laurea', 155),
  ('lavoro', 'Lavoro', 'Dopo la laurea', 156),
  ('orientamento', 'Orientamento', 'Dopo la laurea', 157),
  ('colloqui', 'Colloqui', 'Dopo la laurea', 158),
  ('libri', 'Libri', 'Compravendita', 159),
  ('vendo', 'Vendo', 'Compravendita', 160),
  ('compro', 'Compro', 'Compravendita', 161),
  ('scambio', 'Scambio', 'Compravendita', 162)
) as v (slug, label, category, sort_order)
cross join (select id from public.topics where name = 'Università') t;

-- Tag validi per uno spot di quel canale: da 1 a 3, senza doppioni, tutti
-- esistenti e o generici o dell'argomento del canale. Interna.
create function public.valid_spot_tags(p_channel_id uuid, p_tags text[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_tags is not null
    and cardinality(p_tags) between 1 and 3
    and cardinality(p_tags) = (select count(distinct t) from unnest(p_tags) t)
    and not exists (
      select 1 from unnest(p_tags) t
      where not exists (
        select 1
        from public.tags g
        join public.channels c on c.id = p_channel_id
        where g.slug = t
          and (g.topic_id is null or g.topic_id = c.topic_id)
      )
    );
$$;

revoke execute on function public.valid_spot_tags(uuid, text[])
  from public, anon, authenticated;

-- I tag tra cui scegliere per un canale: prima i generici, poi quelli
-- dell'argomento, ognuno con la sua categoria.
create function public.channel_tags(p_channel_id uuid)
returns table (slug text, label text, category text)
language sql
stable
security definer
set search_path = ''
as $$
  select g.slug, g.label, g.category
  from public.tags g
  join public.channels c on c.id = p_channel_id
  where g.topic_id is null or g.topic_id = c.topic_id
  order by g.sort_order;
$$;

-- Tutti i tag con il nome visibile: serve a mostrare le card, che hanno solo
-- i nomi tecnici.
create function public.all_tags()
returns table (slug text, label text, category text)
language sql
stable
security definer
set search_path = ''
as $$
  select g.slug, g.label, g.category
  from public.tags g
  order by g.sort_order;
$$;

-- ============================================================
-- Approvazione (solo il proprietario del canale)
-- ============================================================

-- true se lo spot era in attesa ed è stato pubblicato. `false` se non esiste
-- o non è in attesa. Tag non validi: 23514.
create function public.approve_spot(p_spot_id uuid, p_tags text[])
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
  v_status text;
begin
  select s.channel_id, s.status into v_channel_id, v_status
  from public.spots s where s.id = p_spot_id;

  if v_channel_id is null then
    return false;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if not public.valid_spot_tags(v_channel_id, p_tags) then
    raise exception 'invalid tags' using errcode = '23514';
  end if;
  if v_status <> 'pending' then
    return false;
  end if;

  update public.spots
  set status = 'published', tags = p_tags
  where id = p_spot_id;
  return true;
end;
$$;

-- true se lo spot era in attesa ed è stato rifiutato.
create function public.reject_spot(p_spot_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
  v_status text;
begin
  select s.channel_id, s.status into v_channel_id, v_status
  from public.spots s where s.id = p_spot_id;

  if v_channel_id is null then
    return false;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if v_status <> 'pending' then
    return false;
  end if;

  update public.spots set status = 'rejected' where id = p_spot_id;
  return true;
end;
$$;

create function public.channel_pending_spots_page(
  p_channel_id uuid,
  p_limit int,
  p_offset int
)
returns table (
  id uuid,
  channel_id uuid,
  title text,
  content text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_channel_owner(p_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;

  -- Dal più vecchio: chi aspetta da più tempo va servito prima.
  return query
    select s.id, s.channel_id, s.title, s.content, s.created_at
    from public.spots s
    where s.channel_id = p_channel_id and s.status = 'pending'
    order by s.created_at, s.id
    limit least(greatest(p_limit, 1), 100)
    offset greatest(p_offset, 0);
end;
$$;

create function public.channel_pending_spots_count(p_channel_id uuid)
returns bigint
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_channel_owner(p_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;

  return (
    select count(*) from public.spots s
    where s.channel_id = p_channel_id and s.status = 'pending'
  );
end;
$$;

-- ============================================================
-- Moderazione: gli spot in attesa o rifiutati non si toccano da qui
-- ============================================================

create or replace function public.set_spot_status(p_spot_id uuid, p_status text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
  v_current text;
begin
  if p_status is null
     or p_status <> all (array['published', 'hidden', 'removed']) then
    raise exception 'invalid status' using errcode = '23514';
  end if;

  select s.channel_id, s.status into v_channel_id, v_current
  from public.spots s where s.id = p_spot_id;

  if v_channel_id is null then
    return false;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  -- `removed` è definitivo; `pending` e `rejected` hanno le loro funzioni.
  if v_current in ('removed', 'pending', 'rejected') or v_current = p_status then
    return false;
  end if;

  update public.spots set status = p_status where id = p_spot_id;
  return true;
end;
$$;

-- ============================================================
-- Letture con i tag (cambia il tipo restituito: vanno ricreate)
-- ============================================================

drop function public.channel_spots_page(uuid, int, int, text);
drop function public.spot_detail(uuid);
drop function public.my_spots_page(int, int);
drop function public.followed_spots_page(int, int);
drop function public.channel_moderation_spots_page(uuid, int, int);

create function public.channel_spots_page(
  p_channel_id uuid,
  p_limit int,
  p_offset int,
  p_query text default null
)
returns table (
  id uuid,
  channel_id uuid,
  title text,
  content text,
  created_at timestamptz,
  like_count bigint,
  comment_count bigint,
  liked_by_me boolean,
  tags text[]
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    s.id, s.channel_id, s.title, s.content, s.created_at,
    (select count(*) from public.spot_likes l where l.spot_id = s.id),
    (select count(*) from public.comments c
      where c.spot_id = s.id and c.status = 'published'),
    exists (
      select 1 from public.spot_likes l
      where l.spot_id = s.id and l.user_id = (select auth.uid())
    ),
    s.tags
  from public.spots s
  where s.channel_id = p_channel_id
    and s.status = 'published'
    and (
      btrim(coalesce(p_query, '')) = ''
      or public.immutable_unaccent(lower(s.title))
           like '%' || public.escape_like(
             public.immutable_unaccent(lower(btrim(p_query)))) || '%'
      or public.immutable_unaccent(lower(s.content))
           like '%' || public.escape_like(
             public.immutable_unaccent(lower(btrim(p_query)))) || '%'
    )
  order by s.created_at desc, s.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

-- Gli spot pubblicati li vedono tutti; quelli nascosti, in attesa o rifiutati
-- il proprietario; quelli in attesa o rifiutati anche l'autore.
create function public.spot_detail(p_spot_id uuid)
returns table (
  id uuid,
  channel_id uuid,
  title text,
  content text,
  created_at timestamptz,
  like_count bigint,
  comment_count bigint,
  liked_by_me boolean,
  status text,
  tags text[]
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    s.id, s.channel_id, s.title, s.content, s.created_at,
    (select count(*) from public.spot_likes l where l.spot_id = s.id),
    (select count(*) from public.comments c
      where c.spot_id = s.id and c.status = 'published'),
    exists (
      select 1 from public.spot_likes l
      where l.spot_id = s.id and l.user_id = (select auth.uid())
    ),
    s.status,
    s.tags
  from public.spots s
  where s.id = p_spot_id
    and (
      s.status = 'published'
      or (s.status in ('hidden', 'pending', 'rejected')
          and public.is_channel_owner(s.channel_id))
      or (s.status in ('pending', 'rejected')
          and s.author_id = (select auth.uid()))
    );
$$;

-- L'autore vede anche i propri spot nascosti, in attesa o rifiutati.
create function public.my_spots_page(p_limit int, p_offset int)
returns table (
  id uuid,
  channel_id uuid,
  channel_name text,
  channel_slug text,
  title text,
  content text,
  created_at timestamptz,
  like_count bigint,
  comment_count bigint,
  liked_by_me boolean,
  status text,
  tags text[]
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    s.id, s.channel_id, c.name, c.slug, s.title, s.content, s.created_at,
    (select count(*) from public.spot_likes l where l.spot_id = s.id),
    (select count(*) from public.comments cm
      where cm.spot_id = s.id and cm.status = 'published'),
    exists (
      select 1 from public.spot_likes l
      where l.spot_id = s.id and l.user_id = (select auth.uid())
    ),
    s.status,
    s.tags
  from public.spots s
  join public.channels c on c.id = s.channel_id
  where s.author_id = (select auth.uid())
    and s.status in ('published', 'hidden', 'pending', 'rejected')
  order by s.created_at desc, s.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

create function public.followed_spots_page(p_limit int, p_offset int)
returns table (
  id uuid,
  channel_id uuid,
  channel_name text,
  channel_slug text,
  title text,
  content text,
  created_at timestamptz,
  like_count bigint,
  comment_count bigint,
  liked_by_me boolean,
  status text,
  tags text[]
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    s.id, s.channel_id, c.name, c.slug, s.title, s.content, s.created_at,
    (select count(*) from public.spot_likes l where l.spot_id = s.id),
    (select count(*) from public.comments cm
      where cm.spot_id = s.id and cm.status = 'published'),
    exists (
      select 1 from public.spot_likes l
      where l.spot_id = s.id and l.user_id = (select auth.uid())
    ),
    s.status,
    s.tags
  from public.subscriptions sub
  join public.spots s on s.channel_id = sub.channel_id
  join public.channels c on c.id = s.channel_id
  where sub.user_id = (select auth.uid())
    and s.status = 'published'
  order by s.created_at desc, s.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

create function public.channel_moderation_spots_page(
  p_channel_id uuid,
  p_limit int,
  p_offset int
)
returns table (
  id uuid,
  channel_id uuid,
  title text,
  content text,
  created_at timestamptz,
  like_count bigint,
  comment_count bigint,
  liked_by_me boolean,
  tags text[]
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_channel_owner(p_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;

  return query
    select
      s.id, s.channel_id, s.title, s.content, s.created_at,
      (select count(*) from public.spot_likes l where l.spot_id = s.id),
      (select count(*) from public.comments c
        where c.spot_id = s.id and c.status = 'published'),
      exists (
        select 1 from public.spot_likes l
        where l.spot_id = s.id and l.user_id = (select auth.uid())
      ),
      s.tags
    from public.spots s
    where s.channel_id = p_channel_id and s.status = 'hidden'
    order by s.created_at desc, s.id
    limit least(greatest(p_limit, 1), 100)
    offset greatest(p_offset, 0);
end;
$$;

-- ============================================================
-- Il proprietario pubblica subito, scegliendo i tag
-- ============================================================

create function public.publish_owner_spot(
  p_channel_id uuid,
  p_title text,
  p_content text,
  p_tags text[]
)
returns table (
  id uuid,
  channel_id uuid,
  title text,
  content text,
  created_at timestamptz,
  like_count bigint,
  comment_count bigint,
  liked_by_me boolean,
  status text,
  tags text[]
)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_title text := btrim(coalesce(p_title, ''));
  v_content text := btrim(coalesce(p_content, ''));
  v_id uuid;
begin
  if (select auth.uid()) is null
     or not public.is_channel_owner(p_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if char_length(v_title) not between 1 and 100 then
    raise exception 'invalid spot title' using errcode = '23514';
  end if;
  if char_length(v_content) not between 1 and 2000 then
    raise exception 'invalid spot content' using errcode = '23514';
  end if;
  if not public.valid_spot_tags(p_channel_id, p_tags) then
    raise exception 'invalid tags' using errcode = '23514';
  end if;

  insert into public.spots (author_id, channel_id, title, content, status, tags)
  values (
    (select auth.uid()), p_channel_id, v_title, v_content, 'published', p_tags
  )
  returning spots.id into v_id;

  return query select * from public.spot_detail(v_id);
end;
$$;

-- ============================================================
-- Permessi: solo gli utenti con una sessione
-- ============================================================

revoke execute on function public.channel_tags(uuid) from public, anon;
revoke execute on function public.all_tags() from public, anon;
revoke execute on function public.approve_spot(uuid, text[]) from public, anon;
revoke execute on function public.reject_spot(uuid) from public, anon;
revoke execute on function public.channel_pending_spots_page(uuid, int, int)
  from public, anon;
revoke execute on function public.channel_pending_spots_count(uuid)
  from public, anon;
revoke execute on function public.set_spot_status(uuid, text) from public, anon;
revoke execute on function public.channel_spots_page(uuid, int, int, text)
  from public, anon;
revoke execute on function public.spot_detail(uuid) from public, anon;
revoke execute on function public.my_spots_page(int, int) from public, anon;
revoke execute on function public.followed_spots_page(int, int)
  from public, anon;
revoke execute on function public.channel_moderation_spots_page(uuid, int, int)
  from public, anon;
revoke execute on function public.publish_owner_spot(uuid, text, text, text[])
  from public, anon;

grant execute on function public.channel_tags(uuid) to authenticated;
grant execute on function public.all_tags() to authenticated;
grant execute on function public.approve_spot(uuid, text[]) to authenticated;
grant execute on function public.reject_spot(uuid) to authenticated;
grant execute on function public.channel_pending_spots_page(uuid, int, int)
  to authenticated;
grant execute on function public.channel_pending_spots_count(uuid)
  to authenticated;
grant execute on function public.set_spot_status(uuid, text) to authenticated;
grant execute on function public.channel_spots_page(uuid, int, int, text)
  to authenticated;
grant execute on function public.spot_detail(uuid) to authenticated;
grant execute on function public.my_spots_page(int, int) to authenticated;
grant execute on function public.followed_spots_page(int, int) to authenticated;
grant execute on function public.channel_moderation_spots_page(uuid, int, int)
  to authenticated;
grant execute on function public.publish_owner_spot(uuid, text, text, text[])
  to authenticated;
