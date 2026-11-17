-- Eventi dei canali (0.9.0).
--
-- Gli eventi sono cose che succedono in una data: li scrive solo il
-- proprietario del canale e li leggono tutti. Come `channel_news`, la tabella è
-- chiusa ai client (RLS attiva, nessuna policy, nessun grant): si usano solo
-- queste funzioni.
--
--   channel_events_page(canale, quando, limite, offset)
--                                  gli eventi di un canale. `quando` è
--                                  'upcoming' (in corso o futuri, dal più
--                                  vicino) o 'past' (già finiti, dal più
--                                  recente); altro dà `23514`
--   event_detail(id)               un evento (vuota se non esiste)
--   create_channel_event(...)      solo il proprietario (`42501`)
--   update_channel_event(...)      solo il proprietario (`42501`); vuota se
--                                  l'evento non esiste
--   delete_channel_event(id)       solo il proprietario (`42501`); `false` se
--                                  non esiste
--
-- Titolo 1-100, descrizione 1-2000, luogo facoltativo fino a 100 caratteri
-- (testo libero, per esempio "Aula magna": il comune c'è già nel canale), inizio
-- obbligatorio e fine facoltativa, mai prima dell'inizio. Violare le regole dà
-- `23514`. Un evento senza fine si considera in corso fino a 3 ore dopo
-- l'inizio. Non c'è nessuna colonna con l'autore: parla il canale. Eliminando il
-- canale spariscono anche i suoi eventi (cascata).

create table public.channel_events (
  id uuid not null default gen_random_uuid(),
  channel_id uuid not null,
  title text not null,
  description text not null,
  location text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  constraint channel_events_pkey primary key (id),
  constraint channel_events_channel_id_fkey
    foreign key (channel_id) references public.channels (id) on delete cascade,
  constraint channel_events_title_check
    check (char_length(title) between 1 and 100),
  constraint channel_events_description_check
    check (char_length(description) between 1 and 2000),
  constraint channel_events_location_check
    check (location is null or char_length(location) between 1 and 100),
  constraint channel_events_dates_check
    check (ends_at is null or ends_at >= starts_at)
);

create index channel_events_channel_starts_idx
  on public.channel_events using btree (channel_id, starts_at);

alter table public.channel_events enable row level security;
revoke all on table public.channel_events from anon, authenticated;

-- ============================================================
-- Lettura
-- ============================================================

create function public.channel_events_page(
  p_channel_id uuid,
  p_when text,
  p_limit int,
  p_offset int
)
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
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  if p_when is null or p_when <> all (array['upcoming', 'past']) then
    raise exception 'invalid events period' using errcode = '23514';
  end if;

  -- In corso o futuri, dal più vicino.
  if p_when = 'upcoming' then
    return query
    select e.id, e.channel_id, c.name, c.slug, e.title, e.description,
           e.location, e.starts_at, e.ends_at, e.created_at
    from public.channel_events e
    join public.channels c on c.id = e.channel_id
    where e.channel_id = p_channel_id
      and coalesce(e.ends_at, e.starts_at + interval '3 hours') >= now()
    order by e.starts_at, e.id
    limit least(greatest(p_limit, 1), 100)
    offset greatest(p_offset, 0);
  -- Già finiti, dal più recente.
  else
    return query
    select e.id, e.channel_id, c.name, c.slug, e.title, e.description,
           e.location, e.starts_at, e.ends_at, e.created_at
    from public.channel_events e
    join public.channels c on c.id = e.channel_id
    where e.channel_id = p_channel_id
      and coalesce(e.ends_at, e.starts_at + interval '3 hours') < now()
    order by e.starts_at desc, e.id
    limit least(greatest(p_limit, 1), 100)
    offset greatest(p_offset, 0);
  end if;
end;
$$;

create function public.event_detail(p_event_id uuid)
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
  from public.channel_events e
  join public.channels c on c.id = e.channel_id
  where e.id = p_event_id;
$$;

-- ============================================================
-- Scrittura (solo il proprietario del canale)
-- ============================================================

create function public.create_channel_event(
  p_channel_id uuid,
  p_title text,
  p_description text,
  p_location text,
  p_starts_at timestamptz,
  p_ends_at timestamptz
)
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
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_title text := btrim(coalesce(p_title, ''));
  v_description text := btrim(coalesce(p_description, ''));
  v_location text := nullif(btrim(coalesce(p_location, '')), '');
  v_id uuid;
begin
  if not public.is_channel_owner(p_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if char_length(v_title) not between 1 and 100 then
    raise exception 'invalid event title' using errcode = '23514';
  end if;
  if char_length(v_description) not between 1 and 2000 then
    raise exception 'invalid event description' using errcode = '23514';
  end if;
  if v_location is not null and char_length(v_location) > 100 then
    raise exception 'invalid event location' using errcode = '23514';
  end if;
  if p_starts_at is null or (p_ends_at is not null and p_ends_at < p_starts_at)
  then
    raise exception 'invalid event dates' using errcode = '23514';
  end if;

  insert into public.channel_events
    (channel_id, title, description, location, starts_at, ends_at)
  values
    (p_channel_id, v_title, v_description, v_location, p_starts_at, p_ends_at)
  returning channel_events.id into v_id;

  return query select * from public.event_detail(v_id);
end;
$$;

create function public.update_channel_event(
  p_event_id uuid,
  p_title text,
  p_description text,
  p_location text,
  p_starts_at timestamptz,
  p_ends_at timestamptz
)
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
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_title text := btrim(coalesce(p_title, ''));
  v_description text := btrim(coalesce(p_description, ''));
  v_location text := nullif(btrim(coalesce(p_location, '')), '');
  v_channel_id uuid;
begin
  select e.channel_id into v_channel_id
  from public.channel_events e where e.id = p_event_id;

  -- Un evento che non esiste: niente da restituire.
  if v_channel_id is null then
    return;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if char_length(v_title) not between 1 and 100 then
    raise exception 'invalid event title' using errcode = '23514';
  end if;
  if char_length(v_description) not between 1 and 2000 then
    raise exception 'invalid event description' using errcode = '23514';
  end if;
  if v_location is not null and char_length(v_location) > 100 then
    raise exception 'invalid event location' using errcode = '23514';
  end if;
  if p_starts_at is null or (p_ends_at is not null and p_ends_at < p_starts_at)
  then
    raise exception 'invalid event dates' using errcode = '23514';
  end if;

  update public.channel_events e
  set title = v_title,
      description = v_description,
      location = v_location,
      starts_at = p_starts_at,
      ends_at = p_ends_at
  where e.id = p_event_id;

  return query select * from public.event_detail(p_event_id);
end;
$$;

create function public.delete_channel_event(p_event_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
begin
  select e.channel_id into v_channel_id
  from public.channel_events e where e.id = p_event_id;

  if v_channel_id is null then
    return false;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;

  delete from public.channel_events where id = p_event_id;
  return true;
end;
$$;

-- Solo gli utenti con una sessione.
revoke execute on function public.channel_events_page(uuid, text, int, int)
  from public, anon;
revoke execute on function public.event_detail(uuid) from public, anon;
revoke execute on function public.create_channel_event(
  uuid, text, text, text, timestamptz, timestamptz) from public, anon;
revoke execute on function public.update_channel_event(
  uuid, text, text, text, timestamptz, timestamptz) from public, anon;
revoke execute on function public.delete_channel_event(uuid)
  from public, anon;

grant execute on function public.channel_events_page(uuid, text, int, int)
  to authenticated;
grant execute on function public.event_detail(uuid) to authenticated;
grant execute on function public.create_channel_event(
  uuid, text, text, text, timestamptz, timestamptz) to authenticated;
grant execute on function public.update_channel_event(
  uuid, text, text, text, timestamptz, timestamptz) to authenticated;
grant execute on function public.delete_channel_event(uuid) to authenticated;
