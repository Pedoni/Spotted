-- Home: i prossimi eventi dei canali seguiti (0.9.0).
--
-- `followed_events_page` restituisce, dal più vicino, gli eventi in corso o
-- futuri dei canali a cui l'utente è iscritto, con nome e slug del canale
-- (stesse colonne di `channel_events_page`). Serve un RPC perché
-- `subscriptions` e `channel_events` sono chiuse ai client. Non restituisce mai
-- id di utenti. Un evento senza fine si considera in corso fino a 3 ore dopo
-- l'inizio (come in `channel_events_page`).
--
-- Non serve un nuovo indice: si parte dalle iscrizioni dell'utente (indice
-- sulla chiave) e per ogni canale si usa `(channel_id, starts_at)`.

create function public.followed_events_page(p_limit int, p_offset int)
returns table (
  id uuid,
  channel_id uuid,
  channel_name text,
  channel_slug text,
  title text,
  description text,
  location text,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select e.id, e.channel_id, c.name, c.slug, e.title, e.description,
         e.location, e.starts_at, e.ends_at, e.created_at
  from public.subscriptions sub
  join public.channel_events e on e.channel_id = sub.channel_id
  join public.channels c on c.id = e.channel_id
  where sub.user_id = (select auth.uid())
    and coalesce(e.ends_at, e.starts_at + interval '3 hours') >= now()
  order by e.starts_at, e.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

revoke execute on function public.followed_events_page(int, int)
  from public, anon;
grant execute on function public.followed_events_page(int, int)
  to authenticated;
