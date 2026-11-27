-- Chat tra un utente e un canale.
--
-- Una chat per (canale, utente). Chi scrive vede sempre "il canale": il
-- proprietario risponde a nome del canale e non compare mai. Il proprietario
-- vede lo username dell'utente (come già vede l'autore degli spot). Non esiste
-- "Rivela identità" in queste chat. Le chat legate agli spot (autore e
-- commentatore) restano com'erano.
--
-- Nascono in due modi:
--   * da uno spot: quando un utente invia uno spot (insert, che nasce `pending`)
--     il database scrive nella chat "spot inviato"; `approve_spot` e
--     `reject_spot` scrivono "spot pubblicato" o "spot rifiutato". I messaggi di
--     sistema li scrive solo il database (kind `spot_sent`, `spot_approved`,
--     `spot_rejected`), mai i client, e portano il titolo dello spot (senza id
--     di utenti);
--   * `start_channel_chat(canale)`: un utente può sempre scrivere al canale.
--     Il proprietario non può scrivere al suo canale (`42501`).
--
-- Chi scrive per primo è sempre l'utente: il proprietario vede la chat solo
-- dopo il primo messaggio dell'utente (niente chat vuote). Gli spot del
-- proprietario non generano messaggi.
--
-- Per i client le chat dei canali stanno nelle stesse funzioni delle altre:
-- `my_chats_page`, `chat_detail`, `chat_messages` e `send_message` ora
-- restituiscono entrambe, con `kind` ('spot' o 'channel'). Per le chat dei
-- canali `i_am_author` è vero per il proprietario (il lato del canale),
-- `other_username` è lo username dell'utente solo per il proprietario, e
-- `identity_revealed` non ha significato. Cambiano i tipi restituiti: le
-- funzioni vengono ricreate. Eliminando il canale spariscono anche queste
-- chat (cascata).
--
-- Tabelle chiuse ai client (RLS senza policy, nessun grant).

-- ============================================================
-- Tabelle
-- ============================================================

create table public.channel_chats (
  id uuid not null default gen_random_uuid(),
  channel_id uuid not null,
  user_id uuid not null,
  created_at timestamptz not null default now(),
  constraint channel_chats_pkey primary key (id),
  constraint channel_chats_channel_user_key unique (channel_id, user_id),
  constraint channel_chats_channel_id_fkey foreign key (channel_id)
    references public.channels (id) on delete cascade,
  constraint channel_chats_user_id_fkey foreign key (user_id)
    references public.profiles (id) on delete cascade
);

create index channel_chats_user_idx on public.channel_chats (user_id);

create table public.channel_chat_messages (
  id uuid not null default gen_random_uuid(),
  chat_id uuid not null,
  -- true: scritto dal proprietario a nome del canale; false: dall'utente.
  from_channel boolean not null,
  kind text not null default 'text',
  spot_id uuid null,
  content text not null,
  created_at timestamptz not null default now(),
  constraint channel_chat_messages_pkey primary key (id),
  constraint channel_chat_messages_chat_id_fkey foreign key (chat_id)
    references public.channel_chats (id) on delete cascade,
  constraint channel_chat_messages_spot_id_fkey foreign key (spot_id)
    references public.spots (id) on delete set null,
  constraint channel_chat_messages_kind_check
    check (kind = any (array[
      'text', 'spot_sent', 'spot_approved', 'spot_rejected'
    ])),
  constraint channel_chat_messages_content_check
    check (char_length(content) between 1 and 5000)
);

create index channel_chat_messages_chat_created_idx
  on public.channel_chat_messages (chat_id, created_at, id);

alter table public.channel_chats enable row level security;
alter table public.channel_chat_messages enable row level security;
revoke all on public.channel_chats from anon, authenticated;
revoke all on public.channel_chat_messages from anon, authenticated;

-- ============================================================
-- Funzioni interne (non chiamabili dai client)
-- ============================================================

-- L'utente corrente è l'utente della chat, oppure il proprietario del canale
-- di una chat in cui l'utente ha già scritto.
create function public.is_channel_chat_participant(p_chat_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.channel_chats c
    join public.channels ch on ch.id = c.channel_id
    where c.id = p_chat_id
      and (
        c.user_id = (select auth.uid())
        or (
          ch.owner_id = (select auth.uid())
          and exists (
            select 1 from public.channel_chat_messages m
            where m.chat_id = c.id and not m.from_channel
          )
        )
      )
  );
$$;

-- Scrive un messaggio di sistema nella chat tra il canale e l'utente (la crea
-- se serve). Niente se l'utente è il proprietario del canale.
create function public.post_channel_message(
  p_channel_id uuid,
  p_user_id uuid,
  p_from_channel boolean,
  p_kind text,
  p_spot_id uuid,
  p_content text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_chat_id uuid;
begin
  if exists (
    select 1 from public.channels c
    where c.id = p_channel_id and c.owner_id = p_user_id
  ) then
    return;
  end if;

  insert into public.channel_chats (channel_id, user_id)
  values (p_channel_id, p_user_id)
  on conflict (channel_id, user_id) do nothing;

  select c.id into v_chat_id
  from public.channel_chats c
  where c.channel_id = p_channel_id and c.user_id = p_user_id;

  insert into public.channel_chat_messages
    (chat_id, from_channel, kind, spot_id, content)
  values (v_chat_id, p_from_channel, p_kind, p_spot_id, p_content);
end;
$$;

-- Un utente che invia uno spot (nasce `pending`) lo trova nella chat col canale.
create function public.spots_post_sent_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'pending' then
    perform public.post_channel_message(
      new.channel_id, new.author_id, false, 'spot_sent', new.id, new.title
    );
  end if;
  return new;
end;
$$;

create trigger spots_post_sent_message
  after insert on public.spots
  for each row execute function public.spots_post_sent_message();

revoke execute on function public.is_channel_chat_participant(uuid)
  from public, anon, authenticated;
revoke execute on function public.post_channel_message(
  uuid, uuid, boolean, text, uuid, text
) from public, anon, authenticated;
revoke execute on function public.spots_post_sent_message()
  from public, anon, authenticated;

-- ============================================================
-- Approvare e rifiutare scrivono nella chat
-- ============================================================

create or replace function public.approve_spot(p_spot_id uuid, p_tags text[])
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
  v_status text;
  v_author_id uuid;
  v_title text;
begin
  select s.channel_id, s.status, s.author_id, s.title
  into v_channel_id, v_status, v_author_id, v_title
  from public.spots s where s.id = p_spot_id;

  if v_channel_id is null then
    return false;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if not public.valid_spot_tags(v_channel_id, p_tags) then
    raise exception 'invalid tags' using errcode = '23514';
  end if;
  if v_status <> 'pending' then
    return false;
  end if;

  update public.spots
  set status = 'published', tags = p_tags
  where id = p_spot_id;

  perform public.post_channel_message(
    v_channel_id, v_author_id, true, 'spot_approved', p_spot_id, v_title
  );
  return true;
end;
$$;

create or replace function public.reject_spot(p_spot_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
  v_status text;
  v_author_id uuid;
  v_title text;
begin
  select s.channel_id, s.status, s.author_id, s.title
  into v_channel_id, v_status, v_author_id, v_title
  from public.spots s where s.id = p_spot_id;

  if v_channel_id is null then
    return false;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if v_status <> 'pending' then
    return false;
  end if;

  update public.spots set status = 'rejected' where id = p_spot_id;

  perform public.post_channel_message(
    v_channel_id, v_author_id, true, 'spot_rejected', p_spot_id, v_title
  );
  return true;
end;
$$;

-- ============================================================
-- Scrivere al canale
-- ============================================================

-- L'id della chat con il canale (la crea se non c'è). Nessuna riga (null) se il
-- canale non esiste. Il proprietario non può scrivere al suo canale (42501).
create function public.start_channel_chat(p_channel_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner_id uuid;
  v_chat_id uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;

  select c.owner_id into v_owner_id
  from public.channels c where c.id = p_channel_id;
  if not found then
    return null;
  end if;
  if v_owner_id = (select auth.uid()) then
    raise exception 'the owner cannot write to their own channel'
      using errcode = '42501';
  end if;

  insert into public.channel_chats (channel_id, user_id)
  values (p_channel_id, (select auth.uid()))
  on conflict (channel_id, user_id) do nothing;

  select c.id into v_chat_id
  from public.channel_chats c
  where c.channel_id = p_channel_id and c.user_id = (select auth.uid());
  return v_chat_id;
end;
$$;

-- ============================================================
-- Letture e scrittura per entrambi i tipi di chat (ricreate)
-- ============================================================

drop function public.my_chats_page(int, int);
drop function public.chat_detail(uuid);
drop function public.chat_messages(uuid, int, int);
drop function public.send_message(uuid, text);
drop function public.visible_chats();

-- Le chat dell'utente corrente, senza id di utenti.
create function public.visible_chats()
returns table (
  id uuid,
  spot_id uuid,
  spot_title text,
  channel_name text,
  channel_slug text,
  i_am_author boolean,
  other_username text,
  identity_revealed boolean,
  created_at timestamptz,
  last_message text,
  last_message_at timestamptz,
  last_message_is_mine boolean,
  kind text,
  last_message_kind text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    c.id,
    c.spot_id,
    s.title,
    ch.name,
    ch.slug,
    c.author_id = (select auth.uid()),
    case
      when c.author_id = (select auth.uid()) then pc.username
      when c.identity_revealed then pa.username
      else null
    end,
    c.identity_revealed,
    c.created_at,
    lm.content,
    lm.created_at,
    lm.sender_id = (select auth.uid()),
    'spot'::text,
    case when lm.created_at is null then null else 'text' end
  from public.chats c
  join public.spots s on s.id = c.spot_id
  join public.channels ch on ch.id = s.channel_id
  join public.profiles pa on pa.id = c.author_id
  join public.profiles pc on pc.id = c.commenter_id
  left join lateral (
    select m.content, m.created_at, m.sender_id
    from public.messages m
    where m.chat_id = c.id
    order by m.created_at desc, m.id desc
    limit 1
  ) lm on true
  where c.author_id = (select auth.uid())
    or (c.commenter_id = (select auth.uid()) and lm.created_at is not null)

  union all

  select
    cc.id,
    null::uuid,
    null::text,
    ch.name,
    ch.slug,
    ch.owner_id = (select auth.uid()),
    case when ch.owner_id = (select auth.uid()) then pu.username else null end,
    true,
    cc.created_at,
    lm.content,
    lm.created_at,
    case
      when cc.user_id = (select auth.uid()) then not lm.from_channel
      else lm.from_channel
    end,
    'channel'::text,
    lm.kind
  from public.channel_chats cc
  join public.channels ch on ch.id = cc.channel_id
  join public.profiles pu on pu.id = cc.user_id
  left join lateral (
    select m.content, m.created_at, m.from_channel, m.kind
    from public.channel_chat_messages m
    where m.chat_id = cc.id
    order by m.created_at desc, m.id desc
    limit 1
  ) lm on true
  where cc.user_id = (select auth.uid())
    or (
      ch.owner_id = (select auth.uid())
      and exists (
        select 1 from public.channel_chat_messages m
        where m.chat_id = cc.id and not m.from_channel
      )
    );
$$;

-- Dalla chat con l'ultimo messaggio più recente.
create function public.my_chats_page(p_limit int, p_offset int)
returns table (
  id uuid,
  spot_id uuid,
  spot_title text,
  channel_name text,
  channel_slug text,
  i_am_author boolean,
  other_username text,
  identity_revealed boolean,
  created_at timestamptz,
  last_message text,
  last_message_at timestamptz,
  last_message_is_mine boolean,
  kind text,
  last_message_kind text
)
language sql
stable
security definer
set search_path = ''
as $$
  select v.*
  from public.visible_chats() v
  order by coalesce(v.last_message_at, v.created_at) desc, v.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

create function public.chat_detail(p_chat_id uuid)
returns table (
  id uuid,
  spot_id uuid,
  spot_title text,
  channel_name text,
  channel_slug text,
  i_am_author boolean,
  other_username text,
  identity_revealed boolean,
  created_at timestamptz,
  last_message text,
  last_message_at timestamptz,
  last_message_is_mine boolean,
  kind text,
  last_message_kind text
)
language sql
stable
security definer
set search_path = ''
as $$
  select v.* from public.visible_chats() v where v.id = p_chat_id;
$$;

-- Dal messaggio più recente. `kind` è `text` o un messaggio di sistema;
-- `spot_id` solo nei messaggi di sistema (nullo se lo spot è stato cancellato).
create function public.chat_messages(
  p_chat_id uuid,
  p_limit int,
  p_offset int
)
returns table (
  id uuid,
  content text,
  created_at timestamptz,
  is_mine boolean,
  kind text,
  spot_id uuid
)
language sql
stable
security definer
set search_path = ''
as $$
  select q.id, q.content, q.created_at, q.is_mine, q.kind, q.spot_id
  from (
    select
      m.id, m.content, m.created_at,
      m.sender_id = (select auth.uid()) as is_mine,
      'text'::text as kind,
      null::uuid as spot_id
    from public.messages m
    where m.chat_id = p_chat_id
      and public.is_chat_participant(p_chat_id)

    union all

    select
      m.id, m.content, m.created_at,
      case
        when c.user_id = (select auth.uid()) then not m.from_channel
        else m.from_channel
      end,
      m.kind,
      m.spot_id
    from public.channel_chat_messages m
    join public.channel_chats c on c.id = m.chat_id
    where m.chat_id = p_chat_id
      and public.is_channel_chat_participant(p_chat_id)
  ) q
  order by q.created_at desc, q.id desc
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

-- Restituisce il messaggio creato, o nessuna riga se la chat non esiste, non è
-- dell'utente (o il commentatore non ha ancora ricevuto un messaggio) o, nelle
-- chat degli spot, lo spot è rimosso. Nelle chat dei canali scrive l'utente o,
-- a nome del canale, il proprietario. Un testo vuoto o troppo lungo fa
-- scattare il check (23514).
create function public.send_message(p_chat_id uuid, p_content text)
returns table (
  id uuid,
  content text,
  created_at timestamptz,
  is_mine boolean,
  kind text,
  spot_id uuid
)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_channel_id uuid;
begin
  if exists (select 1 from public.chats c where c.id = p_chat_id) then
    return query
      with new_message as (
        insert into public.messages (chat_id, sender_id, content)
        select c.id, (select auth.uid()), btrim(p_content)
        from public.chats c
        join public.spots s on s.id = c.spot_id
        where c.id = p_chat_id
          and s.status <> 'removed'
          and (select auth.uid()) is not null
          and public.is_chat_participant(c.id)
        returning messages.id, messages.content, messages.created_at
      )
      select nm.id, nm.content, nm.created_at, true, 'text'::text, null::uuid
      from new_message nm;
    return;
  end if;

  select c.channel_id into v_channel_id
  from public.channel_chats c where c.id = p_chat_id;
  if v_channel_id is null
     or (select auth.uid()) is null
     or not public.is_channel_chat_participant(p_chat_id) then
    return;
  end if;

  return query
    with new_message as (
      insert into public.channel_chat_messages (chat_id, from_channel, content)
      values (
        p_chat_id,
        public.is_channel_owner(v_channel_id),
        btrim(p_content)
      )
      returning
        channel_chat_messages.id,
        channel_chat_messages.content,
        channel_chat_messages.created_at
    )
    select nm.id, nm.content, nm.created_at, true, 'text'::text, null::uuid
    from new_message nm;
end;
$$;

-- ============================================================
-- Permessi
-- ============================================================

revoke execute on function public.visible_chats()
  from public, anon, authenticated;
revoke execute on function public.start_channel_chat(uuid) from public, anon;
revoke execute on function public.my_chats_page(int, int) from public, anon;
revoke execute on function public.chat_detail(uuid) from public, anon;
revoke execute on function public.chat_messages(uuid, int, int)
  from public, anon;
revoke execute on function public.send_message(uuid, text) from public, anon;
revoke execute on function public.approve_spot(uuid, text[]) from public, anon;
revoke execute on function public.reject_spot(uuid) from public, anon;

grant execute on function public.start_channel_chat(uuid) to authenticated;
grant execute on function public.my_chats_page(int, int) to authenticated;
grant execute on function public.chat_detail(uuid) to authenticated;
grant execute on function public.chat_messages(uuid, int, int) to authenticated;
grant execute on function public.send_message(uuid, text) to authenticated;
grant execute on function public.approve_spot(uuid, text[]) to authenticated;
grant execute on function public.reject_spot(uuid) to authenticated;
