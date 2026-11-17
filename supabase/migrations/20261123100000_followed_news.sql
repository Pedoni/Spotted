-- Home: le news dei canali seguiti (0.9.0).
--
-- `followed_news_page` restituisce, dalla più recente, le news dei canali a
-- cui l'utente è iscritto, con nome e slug del canale (stesse colonne di
-- `channel_news_page`). Serve un RPC perché `subscriptions` e `channel_news`
-- sono chiuse ai client. Non restituisce mai id di utenti.
--
-- Non serve un nuovo indice: si parte dalle iscrizioni dell'utente (indice
-- sulla chiave) e per ogni canale si usa `(channel_id, created_at)`.

create function public.followed_news_page(p_limit int, p_offset int)
returns table (
  id uuid,
  channel_id uuid,
  channel_name text,
  channel_slug text,
  title text,
  body text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select n.id, n.channel_id, c.name, c.slug, n.title, n.body, n.created_at
  from public.subscriptions sub
  join public.channel_news n on n.channel_id = sub.channel_id
  join public.channels c on c.id = n.channel_id
  where sub.user_id = (select auth.uid())
  order by n.created_at desc, n.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

revoke execute on function public.followed_news_page(int, int)
  from public, anon;
grant execute on function public.followed_news_page(int, int)
  to authenticated;
