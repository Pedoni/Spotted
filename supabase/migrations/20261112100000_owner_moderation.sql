-- Strumenti del proprietario del canale (0.5.0, parte 1).
--
-- Il proprietario di un canale può:
--   * vedere l'autore di uno spot del suo canale (solo lui: gli altri no);
--   * nascondere/ripristinare/rimuovere gli spot del suo canale;
--   * nascondere/ripristinare i commenti sotto gli spot del suo canale.
--
-- Funzioni nuove (security definer, solo `authenticated`):
--   channel_spot_author(spot_id)                      autore di uno spot (proprietario)
--   set_spot_status(spot_id, status)                  published | hidden | removed
--   set_comment_status(comment_id, status)            published | hidden
--   channel_moderation_spots_page(channel, limit, offset)  spot nascosti del canale
--
-- Funzioni modificate:
--   spot_detail          aggiunge `status`; il proprietario vede anche gli spot nascosti
--   spot_comments        aggiunge `status`; il proprietario vede anche i commenti nascosti
--   my_spots_page        aggiunge `status`; l'autore vede i propri spot nascosti
--   channel_spots_page   i conteggi ignorano i commenti nascosti
--
-- Chi non è proprietario riceve l'errore 42501 (PermissionFailure).

-- ============================================================
-- Stato dei commenti
-- ============================================================

alter table public.comments
  add column status text not null default 'published',
  add constraint comments_status_check
    check (status = any (array['published', 'hidden']));

-- ============================================================
-- Helper: l'utente corrente è proprietario del canale?
-- ============================================================

create or replace function public.is_channel_owner(p_channel_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.channels c
    where c.id = p_channel_id and c.owner_id = (select auth.uid())
  );
$$;

-- ============================================================
-- Autore di uno spot (solo proprietario del canale)
-- ============================================================

create or replace function public.channel_spot_author(p_spot_id uuid)
returns table (author_id uuid, username text)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
begin
  select s.channel_id into v_channel_id
  from public.spots s where s.id = p_spot_id;

  if v_channel_id is null then
    return;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;

  return query
    select s.author_id, p.username
    from public.spots s
    join public.profiles p on p.id = s.author_id
    where s.id = p_spot_id;
end;
$$;

-- ============================================================
-- Moderazione degli spot
-- ============================================================

-- true se lo stato è cambiato. `removed` è definitivo. Stato non valido: 23514.
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
  if v_current = 'removed' or v_current = p_status then
    return false;
  end if;

  update public.spots set status = p_status where id = p_spot_id;
  return true;
end;
$$;

create or replace function public.channel_moderation_spots_page(
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
  liked_by_me boolean
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
      )
    from public.spots s
    where s.channel_id = p_channel_id and s.status = 'hidden'
    order by s.created_at desc, s.id
    limit least(greatest(p_limit, 1), 100)
    offset greatest(p_offset, 0);
end;
$$;

-- ============================================================
-- Moderazione dei commenti
-- ============================================================

-- true se lo stato è cambiato. Stato non valido: 23514.
create or replace function public.set_comment_status(
  p_comment_id uuid,
  p_status text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
  v_current text;
begin
  if p_status is null or p_status <> all (array['published', 'hidden']) then
    raise exception 'invalid status' using errcode = '23514';
  end if;

  select s.channel_id, c.status into v_channel_id, v_current
  from public.comments c
  join public.spots s on s.id = c.spot_id
  where c.id = p_comment_id;

  if v_channel_id is null then
    return false;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if v_current = p_status then
    return false;
  end if;

  update public.comments set status = p_status where id = p_comment_id;
  return true;
end;
$$;

-- ============================================================
-- Letture aggiornate
-- ============================================================

-- Stesso tipo di ritorno: i conteggi ignorano i commenti nascosti.
create or replace function public.channel_spots_page(
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
  liked_by_me boolean
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
    )
  from public.spots s
  where s.channel_id = p_channel_id and s.status = 'published'
  order by s.created_at desc, s.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

-- Cambiano i tipi restituiti (aggiungono `status`): vanno ricreate.
drop function if exists public.spot_detail(uuid);
drop function if exists public.my_spots_page(int, int);
drop function if exists public.spot_comments(uuid, int, int);

-- Gli spot pubblicati li vedono tutti; quelli nascosti solo il proprietario.
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
  status text
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
    s.status
  from public.spots s
  where s.id = p_spot_id
    and (
      s.status = 'published'
      or (s.status = 'hidden' and public.is_channel_owner(s.channel_id))
    );
$$;

-- L'autore vede anche i propri spot nascosti (con `status`), non i rimossi.
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
  status text
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
    s.status
  from public.spots s
  join public.channels c on c.id = s.channel_id
  where s.author_id = (select auth.uid())
    and s.status in ('published', 'hidden')
  order by s.created_at desc, s.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

-- I commenti nascosti li vede solo il proprietario del canale.
create function public.spot_comments(
  p_spot_id uuid,
  p_limit int,
  p_offset int
)
returns table (
  id uuid,
  spot_id uuid,
  content text,
  created_at timestamptz,
  author_username text,
  is_spot_author boolean,
  is_mine boolean,
  like_count bigint,
  liked_by_me boolean,
  status text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    c.id, c.spot_id, c.content, c.created_at,
    -- L'autore dello spot commenta senza nome.
    case when c.author_id = s.author_id then null else p.username end,
    c.author_id = s.author_id,
    coalesce(c.author_id = (select auth.uid()), false),
    (select count(*) from public.comment_likes l where l.comment_id = c.id),
    exists (
      select 1 from public.comment_likes l
      where l.comment_id = c.id and l.user_id = (select auth.uid())
    ),
    c.status
  from public.comments c
  join public.spots s on s.id = c.spot_id
  join public.profiles p on p.id = c.author_id
  where c.spot_id = p_spot_id
    and (
      s.status = 'published'
      or (s.status = 'hidden' and public.is_channel_owner(s.channel_id))
    )
    and (
      c.status = 'published'
      or public.is_channel_owner(s.channel_id)
    )
  order by c.created_at desc, c.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

-- ============================================================
-- Permessi: solo gli utenti autenticati
-- ============================================================

revoke execute on function public.is_channel_owner(uuid) from public, anon;
revoke execute on function public.channel_spot_author(uuid) from public, anon;
revoke execute on function public.set_spot_status(uuid, text) from public, anon;
revoke execute on function public.set_comment_status(uuid, text) from public, anon;
revoke execute on function public.channel_moderation_spots_page(uuid, int, int) from public, anon;
revoke execute on function public.channel_spots_page(uuid, int, int) from public, anon;
revoke execute on function public.spot_detail(uuid) from public, anon;
revoke execute on function public.my_spots_page(int, int) from public, anon;
revoke execute on function public.spot_comments(uuid, int, int) from public, anon;

grant execute on function public.is_channel_owner(uuid) to authenticated;
grant execute on function public.channel_spot_author(uuid) to authenticated;
grant execute on function public.set_spot_status(uuid, text) to authenticated;
grant execute on function public.set_comment_status(uuid, text) to authenticated;
grant execute on function public.channel_moderation_spots_page(uuid, int, int) to authenticated;
grant execute on function public.channel_spots_page(uuid, int, int) to authenticated;
grant execute on function public.spot_detail(uuid) to authenticated;
grant execute on function public.my_spots_page(int, int) to authenticated;
grant execute on function public.spot_comments(uuid, int, int) to authenticated;
