-- Ricerca di testo negli spot di un canale (0.8.0).
--
-- `channel_spots_page` prende un testo di ricerca facoltativo (`p_query`):
-- restano gli spot pubblicati del canale il cui titolo o testo CONTIENE il
-- testo, ovunque (non solo a inizio parola), senza distinguere maiuscole e
-- accenti ("perche" trova "perché"). Senza testo (o con un testo vuoto) è
-- l'elenco di prima.
--
-- Il testo è un'unica sequenza da cercare, non una lista di parole. I
-- caratteri `%`, `_` e `\` valgono come lettere normali (`escape_like`).
--
-- Non serve un indice: la ricerca guarda solo gli spot di quel canale, già
-- ristretti dall'indice su `(channel_id, created_at)`.
--
-- Usa `immutable_unaccent` e `escape_like`, create con la migrazione dei
-- comuni (`20261116100000`).
--
-- La firma cambia (si aggiunge un parametro): la funzione vecchia con tre
-- parametri si elimina, altrimenti con due funzioni dal nome uguale PostgREST
-- non saprebbe quale chiamare. Il nuovo parametro ha un valore di default,
-- quindi le chiamate di prima continuano a funzionare.

drop function if exists public.channel_spots_page(uuid, int, int);

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

revoke execute on function public.channel_spots_page(uuid, int, int, text)
  from public, anon;
grant execute on function public.channel_spots_page(uuid, int, int, text)
  to authenticated;
