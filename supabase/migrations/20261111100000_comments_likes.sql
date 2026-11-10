-- Commenti e like (0.4.0).
--
-- Commenti: non sono anonimi, ma se l'autore dello spot commenta il proprio
-- spot il commento appare come "Autore del post" senza nome. Per questo
-- `comments.author_id` non deve essere leggibile dai client (confrontato con
-- `spots.author_id` rivelerebbe l'autore dello spot): la tabella si legge e si
-- scrive solo tramite funzioni. I commenti non si modificano, solo si cancellano.
--
-- Like: `spot_likes` e `comment_likes` non sono più accessibili ai client (prima
-- esponevano `user_id`). Si usano solo funzioni, che non mostrano mai chi ha
-- messo "mi piace":
--   set_spot_liked(spot_id, liked)           mette/toglie il like a uno spot
--   set_comment_liked(comment_id, liked)     mette/toglie il like a un commento
--
-- Letture (security definer, solo `authenticated`), con conteggi e stato
-- dell'utente corrente:
--   channel_spots_page(channel_id, limit, offset)   spot di un canale
--   spot_detail(spot_id)                            un singolo spot
--   my_spots_page(limit, offset)                    i propri spot (ora con conteggi)
--   spot_comments(spot_id, limit, offset)           commenti di uno spot
--   add_comment(spot_id, content)                   pubblica un commento
--   delete_comment(comment_id)                      cancella un proprio commento

-- ============================================================
-- Chiusura delle tabelle ai client
-- ============================================================

revoke all on public.comments from anon, authenticated;
revoke all on public.spot_likes from anon, authenticated;
revoke all on public.comment_likes from anon, authenticated;

drop policy if exists "Read comments on published spots" on public.comments;
drop policy if exists "Authenticated users create comments" on public.comments;
drop policy if exists "Authors update their comments" on public.comments;
drop policy if exists "Authors delete their comments" on public.comments;

drop policy if exists "Read likes on published spots" on public.spot_likes;
drop policy if exists "Like as yourself" on public.spot_likes;
drop policy if exists "Remove your own likes" on public.spot_likes;

drop policy if exists "Read comment likes" on public.comment_likes;
drop policy if exists "Like comments as yourself" on public.comment_likes;
drop policy if exists "Remove your comment likes" on public.comment_likes;

alter table public.comments
  add constraint comments_content_length
    check (char_length(btrim(content)) between 1 and 500);

-- I conteggi cercano per spot / commento.
create index if not exists spot_likes_spot_idx
  on public.spot_likes using btree (spot_id);
create index if not exists comment_likes_comment_idx
  on public.comment_likes using btree (comment_id);

-- ============================================================
-- Like
-- ============================================================

create or replace function public.set_spot_liked(p_spot_id uuid, p_liked boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_liked then
    insert into public.spot_likes (user_id, spot_id)
    select (select auth.uid()), s.id
    from public.spots s
    where s.id = p_spot_id
      and s.status = 'published'
      and (select auth.uid()) is not null
    on conflict do nothing;
  else
    delete from public.spot_likes
    where user_id = (select auth.uid()) and spot_id = p_spot_id;
  end if;
end;
$$;

create or replace function public.set_comment_liked(p_comment_id uuid, p_liked boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_liked then
    insert into public.comment_likes (user_id, comment_id)
    select (select auth.uid()), c.id
    from public.comments c
    join public.spots s on s.id = c.spot_id
    where c.id = p_comment_id
      and s.status = 'published'
      and (select auth.uid()) is not null
    on conflict do nothing;
  else
    delete from public.comment_likes
    where user_id = (select auth.uid()) and comment_id = p_comment_id;
  end if;
end;
$$;

-- ============================================================
-- Spot con conteggi
-- ============================================================

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
    (select count(*) from public.comments c where c.spot_id = s.id),
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

create or replace function public.spot_detail(p_spot_id uuid)
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
    (select count(*) from public.comments c where c.spot_id = s.id),
    exists (
      select 1 from public.spot_likes l
      where l.spot_id = s.id and l.user_id = (select auth.uid())
    )
  from public.spots s
  where s.id = p_spot_id and s.status = 'published';
$$;

-- Cambia il tipo restituito (aggiunge i conteggi): va ricreata.
drop function if exists public.my_spots_page(int, int);

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
  liked_by_me boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    s.id, s.channel_id, c.name, c.slug, s.title, s.content, s.created_at,
    (select count(*) from public.spot_likes l where l.spot_id = s.id),
    (select count(*) from public.comments cm where cm.spot_id = s.id),
    exists (
      select 1 from public.spot_likes l
      where l.spot_id = s.id and l.user_id = (select auth.uid())
    )
  from public.spots s
  join public.channels c on c.id = s.channel_id
  where s.author_id = (select auth.uid())
    and s.status = 'published'
  order by s.created_at desc, s.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

-- ============================================================
-- Commenti
-- ============================================================

create or replace function public.spot_comments(
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
  liked_by_me boolean
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
    )
  from public.comments c
  join public.spots s on s.id = c.spot_id
  join public.profiles p on p.id = c.author_id
  where c.spot_id = p_spot_id and s.status = 'published'
  order by c.created_at desc, c.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

-- Restituisce il commento creato, o nessuna riga se lo spot non esiste (o non
-- è pubblicato). Un testo troppo lungo o vuoto fa scattare il check (23514).
create or replace function public.add_comment(p_spot_id uuid, p_content text)
returns table (
  id uuid,
  spot_id uuid,
  content text,
  created_at timestamptz,
  author_username text,
  is_spot_author boolean,
  is_mine boolean,
  like_count bigint,
  liked_by_me boolean
)
language sql
security definer
set search_path = ''
as $$
  with new_comment as (
    insert into public.comments (author_id, spot_id, content)
    select (select auth.uid()), s.id, btrim(p_content)
    from public.spots s
    where s.id = p_spot_id
      and s.status = 'published'
      and (select auth.uid()) is not null
    returning id, spot_id, content, created_at, author_id
  )
  select
    nc.id, nc.spot_id, nc.content, nc.created_at,
    case when nc.author_id = s.author_id then null else p.username end,
    nc.author_id = s.author_id,
    true,
    0::bigint,
    false
  from new_comment nc
  join public.spots s on s.id = nc.spot_id
  join public.profiles p on p.id = nc.author_id;
$$;

-- true se il commento era dell'utente ed è stato cancellato.
create or replace function public.delete_comment(p_comment_id uuid)
returns boolean
language sql
security definer
set search_path = ''
as $$
  with deleted as (
    delete from public.comments
    where id = p_comment_id and author_id = (select auth.uid())
    returning 1
  )
  select exists (select 1 from deleted);
$$;

-- ============================================================
-- Permessi: solo gli utenti autenticati
-- ============================================================

revoke execute on function public.set_spot_liked(uuid, boolean) from public, anon;
revoke execute on function public.set_comment_liked(uuid, boolean) from public, anon;
revoke execute on function public.channel_spots_page(uuid, int, int) from public, anon;
revoke execute on function public.spot_detail(uuid) from public, anon;
revoke execute on function public.my_spots_page(int, int) from public, anon;
revoke execute on function public.spot_comments(uuid, int, int) from public, anon;
revoke execute on function public.add_comment(uuid, text) from public, anon;
revoke execute on function public.delete_comment(uuid) from public, anon;

grant execute on function public.set_spot_liked(uuid, boolean) to authenticated;
grant execute on function public.set_comment_liked(uuid, boolean) to authenticated;
grant execute on function public.channel_spots_page(uuid, int, int) to authenticated;
grant execute on function public.spot_detail(uuid) to authenticated;
grant execute on function public.my_spots_page(int, int) to authenticated;
grant execute on function public.spot_comments(uuid, int, int) to authenticated;
grant execute on function public.add_comment(uuid, text) to authenticated;
grant execute on function public.delete_comment(uuid) to authenticated;
