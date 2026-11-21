-- Filtro per tag negli spot di un canale (#86).
--
-- `channel_spots_page` prende un elenco di tag facoltativo (`p_tags`): restano
-- gli spot pubblicati del canale che hanno **almeno uno** dei tag scelti. Si
-- somma alla ricerca di testo (`p_query`): uno spot deve rispettare entrambi.
-- Senza tag (nullo o vuoto) è l'elenco di prima.
--
-- La firma cambia (si aggiunge un parametro): la funzione vecchia con quattro
-- parametri si elimina, altrimenti con due funzioni dal nome uguale PostgREST
-- non saprebbe quale chiamare. Il nuovo parametro ha un valore di default,
-- quindi le chiamate di prima continuano a funzionare.
--
-- Non serve un indice: si filtrano solo gli spot di un canale, già ristretti
-- dall'indice su `(channel_id, created_at)`.

drop function public.channel_spots_page(uuid, int, int, text);

create function public.channel_spots_page(
  p_channel_id uuid,
  p_limit int,
  p_offset int,
  p_query text default null,
  p_tags text[] default null
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
    and (
      coalesce(cardinality(p_tags), 0) = 0
      or s.tags && p_tags
    )
  order by s.created_at desc, s.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

revoke execute on function public.channel_spots_page(
  uuid, int, int, text, text[]
) from public, anon;
grant execute on function public.channel_spots_page(
  uuid, int, int, text, text[]
) to authenticated;
