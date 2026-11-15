-- Modifica ed eliminazione dei canali (0.8.0).
--
-- I client non hanno grant di `update` né di `delete` su `channels` (vedi
-- `20261117100000`): si usano solo queste funzioni, che rispondono `42501`
-- a chi non è il proprietario del canale.
--
--   update_channel(...)  nome, descrizione, argomento e comune. Lo slug (l'indirizzo)
--                        non cambia mai. `place`, `province_code` e `region_name`
--                        li ricalcola il trigger `channels_sync_municipality` dal
--                        comune: se il comune è nullo spariscono.
--   delete_channel(id)   elimina il canale e, a cascata, spot, commenti, "mi
--                        piace", segnalazioni, chat, messaggi e iscrizioni. Non
--                        si può annullare.
--
-- I controlli sono gli stessi dell'app (nome 3-60 caratteri, descrizione fino
-- a 500): violarli dà `23514`.

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
         c.municipality_id, c.province_code, c.region_name, c.created_at
  from public.channels c
  where c.id = p_channel_id;
end;
$$;

create function public.delete_channel(p_channel_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_channel_owner(p_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;

  delete from public.channels c where c.id = p_channel_id;
end;
$$;

revoke execute on function public.update_channel(uuid, text, text, uuid, text)
  from public, anon;
revoke execute on function public.delete_channel(uuid) from public, anon;

grant execute on function public.update_channel(uuid, text, text, uuid, text)
  to authenticated;
grant execute on function public.delete_channel(uuid) to authenticated;
