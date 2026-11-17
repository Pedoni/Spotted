-- News dei canali (0.9.0).
--
-- Le news sono le comunicazioni del canale: le scrive solo il proprietario e le
-- leggono tutti. Come per `spots` e `channels`, la tabella è chiusa ai client
-- (RLS attiva, nessuna policy, nessun grant): si usano solo queste funzioni.
--
--   channel_news_page(canale, limite, offset)  le news di un canale, dalla più
--                                              recente
--   news_detail(id)                            una news (vuota se non esiste)
--   create_channel_news(canale, titolo, testo) solo il proprietario (`42501`)
--   update_channel_news(id, titolo, testo)     solo il proprietario (`42501`);
--                                              vuota se la news non esiste
--   delete_channel_news(id)                    solo il proprietario (`42501`);
--                                              `false` se non esiste
--
-- Titolo 1-100 e testo 1-2000 caratteri (come gli spot): violarli dà `23514`.
-- Non c'è nessuna colonna con l'autore: parla il canale, e il proprietario
-- resta nascosto come in tutta l'app. Eliminando il canale spariscono anche le
-- sue news (cascata).

create table public.channel_news (
  id uuid not null default gen_random_uuid(),
  channel_id uuid not null,
  title text not null,
  body text not null,
  created_at timestamptz not null default now(),
  constraint channel_news_pkey primary key (id),
  constraint channel_news_channel_id_fkey
    foreign key (channel_id) references public.channels (id) on delete cascade,
  constraint channel_news_title_check
    check (char_length(title) between 1 and 100),
  constraint channel_news_body_check
    check (char_length(body) between 1 and 2000)
);

create index channel_news_channel_created_idx
  on public.channel_news using btree (channel_id, created_at desc);

alter table public.channel_news enable row level security;
revoke all on table public.channel_news from anon, authenticated;

-- ============================================================
-- Lettura
-- ============================================================

create function public.channel_news_page(
  p_channel_id uuid,
  p_limit int,
  p_offset int
)
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
  from public.channel_news n
  join public.channels c on c.id = n.channel_id
  where n.channel_id = p_channel_id
  order by n.created_at desc, n.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

create function public.news_detail(p_news_id uuid)
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
  from public.channel_news n
  join public.channels c on c.id = n.channel_id
  where n.id = p_news_id;
$$;

-- ============================================================
-- Scrittura (solo il proprietario del canale)
-- ============================================================

create function public.create_channel_news(
  p_channel_id uuid,
  p_title text,
  p_body text
)
returns table (
  id uuid,
  channel_id uuid,
  channel_name text,
  channel_slug text,
  title text,
  body text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_title text := btrim(coalesce(p_title, ''));
  v_body text := btrim(coalesce(p_body, ''));
  v_id uuid;
begin
  if not public.is_channel_owner(p_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if char_length(v_title) not between 1 and 100 then
    raise exception 'invalid news title' using errcode = '23514';
  end if;
  if char_length(v_body) not between 1 and 2000 then
    raise exception 'invalid news body' using errcode = '23514';
  end if;

  insert into public.channel_news (channel_id, title, body)
  values (p_channel_id, v_title, v_body)
  returning channel_news.id into v_id;

  return query select * from public.news_detail(v_id);
end;
$$;

create function public.update_channel_news(
  p_news_id uuid,
  p_title text,
  p_body text
)
returns table (
  id uuid,
  channel_id uuid,
  channel_name text,
  channel_slug text,
  title text,
  body text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_title text := btrim(coalesce(p_title, ''));
  v_body text := btrim(coalesce(p_body, ''));
  v_channel_id uuid;
begin
  select n.channel_id into v_channel_id
  from public.channel_news n where n.id = p_news_id;

  -- Una news che non esiste: niente da restituire.
  if v_channel_id is null then
    return;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if char_length(v_title) not between 1 and 100 then
    raise exception 'invalid news title' using errcode = '23514';
  end if;
  if char_length(v_body) not between 1 and 2000 then
    raise exception 'invalid news body' using errcode = '23514';
  end if;

  update public.channel_news n
  set title = v_title, body = v_body
  where n.id = p_news_id;

  return query select * from public.news_detail(p_news_id);
end;
$$;

create function public.delete_channel_news(p_news_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
begin
  select n.channel_id into v_channel_id
  from public.channel_news n where n.id = p_news_id;

  if v_channel_id is null then
    return false;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;

  delete from public.channel_news where id = p_news_id;
  return true;
end;
$$;

-- Solo gli utenti con una sessione.
revoke execute on function public.channel_news_page(uuid, int, int)
  from public, anon;
revoke execute on function public.news_detail(uuid) from public, anon;
revoke execute on function public.create_channel_news(uuid, text, text)
  from public, anon;
revoke execute on function public.update_channel_news(uuid, text, text)
  from public, anon;
revoke execute on function public.delete_channel_news(uuid) from public, anon;

grant execute on function public.channel_news_page(uuid, int, int)
  to authenticated;
grant execute on function public.news_detail(uuid) to authenticated;
grant execute on function public.create_channel_news(uuid, text, text)
  to authenticated;
grant execute on function public.update_channel_news(uuid, text, text)
  to authenticated;
grant execute on function public.delete_channel_news(uuid) to authenticated;
