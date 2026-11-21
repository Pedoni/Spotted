-- Limiti e blocco nelle chat con i canali, e per gli spot (#90).
--
-- Oggi chiunque può scrivere a qualunque canale e inviare spot senza limiti.
-- Questa migrazione aggiunge:
--
--   * un limite di **5 messaggi senza risposta** per utente in ogni chat con un
--     canale: contano i messaggi dell'utente (non quelli di sistema) scritti
--     dopo l'ultimo messaggio del canale; quando il canale scrive, anche
--     pubblicando o rifiutando uno spot, il conteggio riparte. Oltre il limite
--     `send_message` risponde con l'errore `SP001`;
--   * un limite di **5 spot in attesa** per utente in ogni canale: oltre il
--     limite l'insert di uno spot risponde con l'errore `SP002`;
--   * il **blocco**: il proprietario blocca un utente dalla chat con lui.
--     Un utente bloccato non può né scrivere al canale né inviargli spot (errore
--     `42501`, generico: non dice chi lo ha bloccato; del resto il proprietario
--     è anonimo). Gli spot già in attesa restano in coda.
--
-- Il blocco sta in `channel_blocks`, chiusa ai client come le altre. Il
-- proprietario non vede mai id di utenti: blocca e sblocca dalla chat
-- (`set_chat_user_blocked(chat, bloccato)`) o dall'elenco dei bloccati con un
-- id del blocco (`channel_blocked_users`, `unblock_channel_user`). Chi non è il
-- proprietario riceve `42501`.

-- ============================================================
-- Blocchi
-- ============================================================

create table public.channel_blocks (
  id uuid not null default gen_random_uuid(),
  channel_id uuid not null,
  user_id uuid not null,
  created_at timestamptz not null default now(),
  constraint channel_blocks_pkey primary key (id),
  constraint channel_blocks_channel_user_key unique (channel_id, user_id),
  constraint channel_blocks_channel_id_fkey foreign key (channel_id)
    references public.channels (id) on delete cascade,
  constraint channel_blocks_user_id_fkey foreign key (user_id)
    references public.profiles (id) on delete cascade
);

alter table public.channel_blocks enable row level security;
revoke all on public.channel_blocks from anon, authenticated;

-- Interna: l'utente è bloccato dal canale.
create function public.is_blocked_from_channel(
  p_channel_id uuid,
  p_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.channel_blocks b
    where b.channel_id = p_channel_id and b.user_id = p_user_id
  );
$$;

revoke execute on function public.is_blocked_from_channel(uuid, uuid)
  from public, anon, authenticated;

-- ============================================================
-- Spot: utente bloccato e troppi spot in attesa
-- ============================================================

create function public.spots_check_sender()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'pending' then
    if public.is_blocked_from_channel(new.channel_id, new.author_id) then
      raise exception 'not allowed to write to this channel'
        using errcode = '42501';
    end if;
    if (
      select count(*) from public.spots s
      where s.channel_id = new.channel_id
        and s.author_id = new.author_id
        and s.status = 'pending'
    ) >= 5 then
      raise exception 'too many pending spots' using errcode = 'SP002';
    end if;
  end if;
  return new;
end;
$$;

create trigger spots_check_sender
  before insert on public.spots
  for each row execute function public.spots_check_sender();

revoke execute on function public.spots_check_sender()
  from public, anon, authenticated;

-- ============================================================
-- Messaggi: utente bloccato e troppi messaggi senza risposta
-- ============================================================

-- Come prima, con i due controlli nelle chat dei canali (solo per chi scrive
-- come utente: il proprietario non ha limiti).
create or replace function public.send_message(p_chat_id uuid, p_content text)
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
  v_owner boolean;
  v_unanswered bigint;
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

  v_owner := public.is_channel_owner(v_channel_id);
  if not v_owner then
    if public.is_blocked_from_channel(v_channel_id, (select auth.uid())) then
      raise exception 'not allowed to write to this channel'
        using errcode = '42501';
    end if;

    select count(*) into v_unanswered
    from public.channel_chat_messages m
    where m.chat_id = p_chat_id
      and m.kind = 'text'
      and not m.from_channel
      and m.created_at > coalesce(
        (select max(r.created_at)
         from public.channel_chat_messages r
         where r.chat_id = p_chat_id and r.from_channel),
        '-infinity'
      );
    if v_unanswered >= 5 then
      raise exception 'too many unanswered messages' using errcode = 'SP001';
    end if;
  end if;

  return query
    with new_message as (
      insert into public.channel_chat_messages (chat_id, from_channel, content)
      values (p_chat_id, v_owner, btrim(p_content))
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
-- Bloccare e sbloccare (solo il proprietario)
-- ============================================================

-- Blocca o sblocca l'utente di una chat con il canale. true se lo stato è
-- cambiato; false se la chat non esiste (o non è con un canale) o l'utente era
-- già in quello stato.
create function public.set_chat_user_blocked(p_chat_id uuid, p_blocked boolean)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
  v_user_id uuid;
begin
  select c.channel_id, c.user_id into v_channel_id, v_user_id
  from public.channel_chats c where c.id = p_chat_id;
  if v_channel_id is null then
    return false;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;

  if p_blocked then
    insert into public.channel_blocks (channel_id, user_id)
    values (v_channel_id, v_user_id)
    on conflict (channel_id, user_id) do nothing;
    return found;
  end if;

  delete from public.channel_blocks b
  where b.channel_id = v_channel_id and b.user_id = v_user_id;
  return found;
end;
$$;

-- L'utente di questa chat è bloccato? Solo per il proprietario; per tutti gli
-- altri è sempre false (non si rivela a chi scrive di essere stato bloccato).
create function public.is_chat_user_blocked(p_chat_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.channel_chats c
    join public.channel_blocks b
      on b.channel_id = c.channel_id and b.user_id = c.user_id
    where c.id = p_chat_id
      and public.is_channel_owner(c.channel_id)
  );
$$;

-- Gli utenti bloccati dal canale, dal più recente. L'id è quello del blocco,
-- non dell'utente.
create function public.channel_blocked_users(
  p_channel_id uuid,
  p_limit int,
  p_offset int
)
returns table (id uuid, username text, created_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_channel_owner(p_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;

  return query
    select b.id, p.username, b.created_at
    from public.channel_blocks b
    join public.profiles p on p.id = b.user_id
    where b.channel_id = p_channel_id
    order by b.created_at desc, b.id
    limit least(greatest(p_limit, 1), 100)
    offset greatest(p_offset, 0);
end;
$$;

-- true se il blocco c'era ed è stato tolto.
create function public.unblock_channel_user(p_block_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
begin
  select b.channel_id into v_channel_id
  from public.channel_blocks b where b.id = p_block_id;
  if v_channel_id is null then
    return false;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;

  delete from public.channel_blocks where id = p_block_id;
  return true;
end;
$$;

-- ============================================================
-- Permessi
-- ============================================================

revoke execute on function public.send_message(uuid, text) from public, anon;
revoke execute on function public.set_chat_user_blocked(uuid, boolean)
  from public, anon;
revoke execute on function public.is_chat_user_blocked(uuid) from public, anon;
revoke execute on function public.channel_blocked_users(uuid, int, int)
  from public, anon;
revoke execute on function public.unblock_channel_user(uuid) from public, anon;

grant execute on function public.send_message(uuid, text) to authenticated;
grant execute on function public.set_chat_user_blocked(uuid, boolean)
  to authenticated;
grant execute on function public.is_chat_user_blocked(uuid) to authenticated;
grant execute on function public.channel_blocked_users(uuid, int, int)
  to authenticated;
grant execute on function public.unblock_channel_user(uuid) to authenticated;
