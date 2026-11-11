-- Chat con rivelazione dell'identità (0.6.0, parte 1: schema).
--
-- Una chat nasce solo da uno spot: la avvia l'autore dello spot con una persona
-- che ha commentato. L'autore vede lo username dell'altro; l'altro vede l'autore
-- solo come "Autore del post" finché l'autore non preme "Rivela identità" (non
-- è reversibile). Una chat per (spot, commentatore). Non esistono chat libere.
--
-- Chiude il debito di sicurezza: `chats` e `messages` esponevano gli id dei
-- partecipanti. Ora si chiudono ai client (come `comments`) e si usano solo
-- funzioni, che non restituiscono mai id di utenti: al loro posto
-- `i_am_author`, `is_mine` e `other_username` (nullo per il commentatore finché
-- l'identità non è rivelata).
--
-- Funzioni (security definer, solo `authenticated`):
--   start_chat(comment_id)                 avvia (o riapre) la chat col commentatore
--   reveal_identity(chat_id)               l'autore mostra il suo username
--   my_chats_page(limit, offset)           le mie chat, dalla più recente
--   chat_detail(chat_id)                   una chat
--   chat_messages(chat_id, limit, offset)  messaggi di una chat, dal più recente
--   send_message(chat_id, content)         scrive un messaggio
--
-- Il commentatore vede la chat solo dopo il primo messaggio dell'autore (niente
-- chat vuote). Sugli spot rimossi non si scrivono nuovi messaggi.
--
-- Errori: chi non è l'autore dello spot riceve 42501 (PermissionFailure) su
-- start_chat e reveal_identity; una chat con sé stessi o un testo vuoto o più
-- lungo di 5000 caratteri danno 23514 (ValidationFailure).

-- ============================================================
-- Le vecchie tabelle devono essere vuote
-- ============================================================

-- Nessun client le usava; se qualcuno ha scritto direttamente nell'API ci si
-- ferma invece di cancellare.
do $$
begin
  if exists (select 1 from public.chats)
     or exists (select 1 from public.messages) then
    raise exception 'chats or messages contain rows: migrate them first';
  end if;
end;
$$;

drop table public.messages;
drop table public.chats;

-- ============================================================
-- Nuovo schema
-- ============================================================

create table public.chats (
  id uuid not null default gen_random_uuid(),
  spot_id uuid not null,
  author_id uuid not null,
  commenter_id uuid not null,
  identity_revealed boolean not null default false,
  created_at timestamptz not null default now(),
  constraint chats_pkey primary key (id),
  constraint chats_spot_commenter_key unique (spot_id, commenter_id),
  constraint chats_spot_id_fkey foreign key (spot_id)
    references public.spots (id) on delete cascade,
  constraint chats_author_id_fkey foreign key (author_id)
    references public.profiles (id) on delete cascade,
  constraint chats_commenter_id_fkey foreign key (commenter_id)
    references public.profiles (id) on delete cascade,
  constraint chats_participants_check check (author_id <> commenter_id)
);

create index chats_author_idx on public.chats (author_id);
create index chats_commenter_idx on public.chats (commenter_id);

create table public.messages (
  id uuid not null default gen_random_uuid(),
  chat_id uuid not null,
  sender_id uuid not null,
  content text not null,
  created_at timestamptz not null default now(),
  constraint messages_pkey primary key (id),
  constraint messages_chat_id_fkey foreign key (chat_id)
    references public.chats (id) on delete cascade,
  constraint messages_sender_id_fkey foreign key (sender_id)
    references public.profiles (id) on delete cascade,
  constraint messages_content_check
    check (length(content) >= 1 and length(content) <= 5000)
);

create index messages_chat_created_idx
  on public.messages (chat_id, created_at, id);

-- Chiuse ai client: si leggono e scrivono solo con le funzioni.
alter table public.chats enable row level security;
alter table public.messages enable row level security;
revoke all on public.chats from anon, authenticated;
revoke all on public.messages from anon, authenticated;

-- ============================================================
-- Funzioni interne (non chiamabili dai client)
-- ============================================================

-- L'utente corrente è l'autore della chat, oppure il commentatore di una chat
-- in cui l'autore ha già scritto.
create or replace function public.is_chat_participant(p_chat_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.chats c
    where c.id = p_chat_id
      and (
        c.author_id = (select auth.uid())
        or (
          c.commenter_id = (select auth.uid())
          and exists (select 1 from public.messages m where m.chat_id = c.id)
        )
      )
  );
$$;

-- Le chat dell'utente corrente, senza id di utenti. `other_username` è lo
-- username dell'altra persona: sempre per l'autore, per il commentatore solo a
-- identità rivelata.
create or replace function public.visible_chats()
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
  last_message_is_mine boolean
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
    lm.sender_id = (select auth.uid())
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
    or (c.commenter_id = (select auth.uid()) and lm.created_at is not null);
$$;

-- ============================================================
-- Avviare una chat e rivelare l'identità
-- ============================================================

-- L'id della chat con chi ha scritto il commento; se esiste già, quella.
-- Nessuna riga (null) se il commento non esiste, non è pubblicato o lo spot è
-- rimosso.
create or replace function public.start_chat(p_comment_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_spot_id uuid;
  v_author_id uuid;
  v_commenter_id uuid;
  v_chat_id uuid;
begin
  select c.spot_id, s.author_id, c.author_id
  into v_spot_id, v_author_id, v_commenter_id
  from public.comments c
  join public.spots s on s.id = c.spot_id
  where c.id = p_comment_id
    and c.status = 'published'
    and s.status <> 'removed';

  if v_spot_id is null then
    return null;
  end if;
  if v_author_id is distinct from (select auth.uid()) then
    raise exception 'only the spot author can start a chat'
      using errcode = '42501';
  end if;
  if v_commenter_id = v_author_id then
    raise exception 'cannot chat with yourself' using errcode = '23514';
  end if;

  insert into public.chats (spot_id, author_id, commenter_id)
  values (v_spot_id, v_author_id, v_commenter_id)
  on conflict (spot_id, commenter_id) do nothing;

  select c.id into v_chat_id
  from public.chats c
  where c.spot_id = v_spot_id and c.commenter_id = v_commenter_id;
  return v_chat_id;
end;
$$;

-- true se l'identità è stata rivelata ora; false se la chat non esiste (o non
-- è dell'utente) o era già rivelata. Non si può tornare indietro.
create or replace function public.reveal_identity(p_chat_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_author_id uuid;
  v_revealed boolean;
begin
  if not public.is_chat_participant(p_chat_id) then
    return false;
  end if;

  select c.author_id, c.identity_revealed into v_author_id, v_revealed
  from public.chats c where c.id = p_chat_id;

  if v_author_id is distinct from (select auth.uid()) then
    raise exception 'only the spot author can reveal their identity'
      using errcode = '42501';
  end if;
  if v_revealed then
    return false;
  end if;

  update public.chats set identity_revealed = true where id = p_chat_id;
  return true;
end;
$$;

-- ============================================================
-- Letture
-- ============================================================

-- Dalla chat con l'ultimo messaggio più recente.
create or replace function public.my_chats_page(p_limit int, p_offset int)
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
  last_message_is_mine boolean
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

create or replace function public.chat_detail(p_chat_id uuid)
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
  last_message_is_mine boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select v.* from public.visible_chats() v where v.id = p_chat_id;
$$;

-- Dal messaggio più recente.
create or replace function public.chat_messages(
  p_chat_id uuid,
  p_limit int,
  p_offset int
)
returns table (
  id uuid,
  content text,
  created_at timestamptz,
  is_mine boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select m.id, m.content, m.created_at, m.sender_id = (select auth.uid())
  from public.messages m
  where m.chat_id = p_chat_id
    and public.is_chat_participant(p_chat_id)
  order by m.created_at desc, m.id desc
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

-- Restituisce il messaggio creato, o nessuna riga se la chat non esiste, non è
-- dell'utente (o il commentatore non ha ancora ricevuto un messaggio) o lo spot
-- è rimosso. Un testo vuoto o troppo lungo fa scattare il check (23514).
create or replace function public.send_message(p_chat_id uuid, p_content text)
returns table (
  id uuid,
  content text,
  created_at timestamptz,
  is_mine boolean
)
language sql
security definer
set search_path = ''
as $$
  with new_message as (
    insert into public.messages (chat_id, sender_id, content)
    select c.id, (select auth.uid()), btrim(p_content)
    from public.chats c
    join public.spots s on s.id = c.spot_id
    where c.id = p_chat_id
      and s.status <> 'removed'
      and (select auth.uid()) is not null
      and public.is_chat_participant(c.id)
    returning id, content, created_at
  )
  select nm.id, nm.content, nm.created_at, true from new_message nm;
$$;

-- ============================================================
-- Permessi
-- ============================================================

-- Interne: usate solo dalle altre funzioni.
revoke execute on function public.is_chat_participant(uuid)
  from public, anon, authenticated;
revoke execute on function public.visible_chats()
  from public, anon, authenticated;

-- Per i client: solo gli utenti autenticati.
revoke execute on function public.start_chat(uuid) from public, anon;
revoke execute on function public.reveal_identity(uuid) from public, anon;
revoke execute on function public.my_chats_page(int, int) from public, anon;
revoke execute on function public.chat_detail(uuid) from public, anon;
revoke execute on function public.chat_messages(uuid, int, int) from public, anon;
revoke execute on function public.send_message(uuid, text) from public, anon;

grant execute on function public.start_chat(uuid) to authenticated;
grant execute on function public.reveal_identity(uuid) to authenticated;
grant execute on function public.my_chats_page(int, int) to authenticated;
grant execute on function public.chat_detail(uuid) to authenticated;
grant execute on function public.chat_messages(uuid, int, int) to authenticated;
grant execute on function public.send_message(uuid, text) to authenticated;
