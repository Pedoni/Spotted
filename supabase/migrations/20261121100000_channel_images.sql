-- Foto e copertina dei canali (0.9.0).
--
-- Ogni canale può avere due immagini, salvate nello storage di Supabase:
--   avatar  la foto, quadrata
--   cover   la copertina, larga (8:3)
--
-- Le immagini stanno nel bucket pubblico `channel-images`, in una cartella per
-- canale: `<id del canale>/avatar-<millisecondi>.jpg` e
-- `<id del canale>/cover-<millisecondi>.jpg`. Il nome cambia a ogni
-- caricamento: così la CDN non serve mai una versione vecchia e non serve
-- sovrascrivere (`upsert`). Nel database si salva solo il percorso.
--
-- ANONIMATO DEL PROPRIETARIO. Lo storage registra chi ha caricato ogni file
-- (`storage.objects.owner_id`): se i client potessero leggere quella tabella
-- scoprirebbero il proprietario del canale, che non va mostrato a nessuno. Per
-- questo le regole su `storage.objects` sono tutte limitate al proprietario del
-- canale: gli altri non possono né elencare né cancellare né caricare. Le
-- immagini si vedono lo stesso, perché un bucket pubblico serve i file per
-- indirizzo senza passare dalle regole.
--
-- Il percorso nel database lo scrive solo la funzione `set_channel_image`
-- (nessun grant di scrittura sulle colonne), che controlla il proprietario e il
-- formato del percorso e restituisce quello precedente, perché l'app lo tolga
-- dallo storage.
--
-- Cambiano anche due funzioni che restituiscono un elenco di colonne:
-- `update_channel` e `my_subscribed_channels` (si eliminano e si ricreano,
-- perché non si può cambiare il tipo restituito).

-- ============================================================
-- Colonne
-- ============================================================

alter table public.channels
  add column avatar_path text,
  add column cover_path text;

-- Leggibili da tutti (come le altre colonne pubbliche); non scrivibili.
grant select (avatar_path, cover_path)
  on public.channels to anon, authenticated;

-- ============================================================
-- Bucket
-- ============================================================

-- Pubblico, con un tetto di 1 MB a file (l'app li riduce molto prima) e solo
-- immagini.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'channel-images',
  'channel-images',
  true,
  1048576,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- ============================================================
-- Regole sullo storage
-- ============================================================

-- Vero se `p_name` (il percorso di un file) sta nella cartella di un canale
-- dell'utente che chiama. Un percorso che non inizia con un uuid dà falso (il
-- `case` evita di convertire testo non valido).
create function public.is_channel_image_owner(p_name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/'
      then public.is_channel_owner(split_part(p_name, '/', 1)::uuid)
    else false
  end;
$$;

revoke execute on function public.is_channel_image_owner(text) from public, anon;
grant execute on function public.is_channel_image_owner(text) to authenticated;

-- Solo il proprietario carica, legge l'elenco e cancella i file della cartella
-- del suo canale. Niente `update`: non si sovrascrive mai.
create policy "Channel owners upload their channel images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'channel-images' and public.is_channel_image_owner(name)
  );

create policy "Channel owners read their channel images"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'channel-images' and public.is_channel_image_owner(name)
  );

create policy "Channel owners delete their channel images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'channel-images' and public.is_channel_image_owner(name)
  );

-- ============================================================
-- Cambiare o togliere un'immagine
-- ============================================================

-- Collega un'immagine già caricata al canale (o la toglie, con `p_path` nullo)
-- e restituisce il percorso precedente, o null se non c'era.
create function public.set_channel_image(
  p_channel_id uuid,
  p_kind text,
  p_path text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old text;
begin
  if not public.is_channel_owner(p_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if p_kind is null or p_kind <> all (array['avatar', 'cover']) then
    raise exception 'invalid image kind' using errcode = '23514';
  end if;
  -- Il file deve stare nella cartella del canale e avere il nome previsto.
  if p_path is not null
     and p_path !~ ('^' || p_channel_id::text || '/' || p_kind || '-[0-9]+\.jpg$') then
    raise exception 'invalid image path' using errcode = '23514';
  end if;

  select case when p_kind = 'avatar' then c.avatar_path else c.cover_path end
  into v_old
  from public.channels c
  where c.id = p_channel_id;

  update public.channels c
  set avatar_path = case when p_kind = 'avatar' then p_path else c.avatar_path end,
      cover_path = case when p_kind = 'cover' then p_path else c.cover_path end
  where c.id = p_channel_id;

  return v_old;
end;
$$;

revoke execute on function public.set_channel_image(uuid, text, text)
  from public, anon;
grant execute on function public.set_channel_image(uuid, text, text)
  to authenticated;

-- ============================================================
-- Funzioni che restituiscono i canali: ora con i percorsi delle immagini
-- ============================================================

drop function public.update_channel(uuid, text, text, uuid, text);

create function public.update_channel(
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

drop function public.my_subscribed_channels();

create function public.my_subscribed_channels()
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
language sql
security definer
set search_path = ''
as $$
  select c.id, c.topic_id, c.name, c.slug, c.description, c.place,
         c.municipality_id, c.province_code, c.region_name,
         c.avatar_path, c.cover_path, c.created_at
  from public.subscriptions s
  join public.channels c on c.id = s.channel_id
  where s.user_id = (select auth.uid())
  order by s.created_at desc
  limit 100;
$$;

revoke execute on function public.my_subscribed_channels() from public, anon;
grant execute on function public.my_subscribed_channels() to authenticated;
