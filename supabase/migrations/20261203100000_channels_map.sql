-- Mappa dei canali (#58).
--
-- `channels_map` restituisce, per ogni comune che ha almeno un canale, un
-- "pin": le coordinate del comune e quanti canali ci sono. Se il canale è uno
-- solo ci sono anche il suo id, nome, slug e foto (il pin mostra la foto del
-- canale e un tocco lo apre); se sono di più il pin mostra il numero e un
-- tocco apre l'elenco dei canali del comune (che l'app legge con i filtri
-- di sempre su `channels`, per comune).
--
-- Gli stessi filtri di Esplora: testo nel nome (come `ilike '%testo%'`, con
-- `%`, `_` e `\` come lettere normali), argomento, regione, provincia e comune.
-- Senza filtri sono tutti i canali con una città (i canali nati senza città
-- non compaiono: l'app invita il proprietario ad aggiungerla).
--
-- Nessun id di utenti: come per `my_subscribed_channels`, il proprietario non
-- è mai restituito. Al massimo 2.000 pin, dai comuni con più canali.
--
-- Eseguire dopo le migrazioni delle coordinate (`20261202100000`..
-- `20261202100400`).

create function public.channels_map(
  p_query text default null,
  p_topic_id uuid default null,
  p_region_name text default null,
  p_province_code text default null,
  p_municipality_id text default null
)
returns table (
  municipality_id text,
  municipality_label text,
  latitude double precision,
  longitude double precision,
  channel_count bigint,
  channel_id uuid,
  channel_name text,
  channel_slug text,
  channel_avatar_path text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    m.istat_code,
    m.name || ' (' || m.province_code || ')',
    m.latitude::double precision,
    m.longitude::double precision,
    count(*),
    -- Solo se il canale è uno: altrimenti sono nulli.
    case when count(*) = 1 then (array_agg(c.id))[1] end,
    case when count(*) = 1 then (array_agg(c.name))[1] end,
    case when count(*) = 1 then (array_agg(c.slug))[1] end,
    case when count(*) = 1 then (array_agg(c.avatar_path))[1] end
  from public.channels c
  join public.municipalities m on m.istat_code = c.municipality_id
  where m.latitude is not null
    and (p_topic_id is null or c.topic_id = p_topic_id)
    and (p_region_name is null or c.region_name = p_region_name)
    and (p_province_code is null or c.province_code = p_province_code)
    and (p_municipality_id is null or c.municipality_id = p_municipality_id)
    and (
      btrim(coalesce(p_query, '')) = ''
      or c.name ilike '%' || public.escape_like(btrim(p_query)) || '%'
    )
  group by m.istat_code, m.name, m.province_code, m.latitude, m.longitude
  order by count(*) desc, m.istat_code
  limit 2000;
$$;

revoke execute on function public.channels_map(text, uuid, text, text, text)
  from public, anon;
grant execute on function public.channels_map(text, uuid, text, text, text)
  to authenticated;
