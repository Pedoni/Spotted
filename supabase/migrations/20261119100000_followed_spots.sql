-- Home: gli spot dei canali seguiti (0.8.0).
--
-- `followed_spots_page` restituisce, dal più recente, gli spot pubblicati
-- nei canali a cui l'utente è iscritto, con nome e slug del canale (stesse
-- colonne di `my_spots_page`). Serve un RPC perché `subscriptions` è chiusa
-- ai client e `spots.author_id` non è leggibile: la funzione non restituisce
-- mai id di utenti.
--
-- Non serve un nuovo indice: si parte dalle iscrizioni dell'utente (indice
-- sulla chiave) e per ogni canale si usa `(channel_id, created_at)` degli spot.

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
  from public.subscriptions sub
  join public.spots s on s.channel_id = sub.channel_id
  join public.channels c on c.id = s.channel_id
  where sub.user_id = (select auth.uid())
    and s.status = 'published'
  order by s.created_at desc, s.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

revoke execute on function public.followed_spots_page(int, int)
  from public, anon;
grant execute on function public.followed_spots_page(int, int)
  to authenticated;
