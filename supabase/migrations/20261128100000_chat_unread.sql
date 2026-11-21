-- Messaggi non letti nelle chat.
--
-- Ogni lato di una chat ricorda quando l'ha letta l'ultima volta
-- (`author_read_at` e `commenter_read_at` nelle chat degli spot, `user_read_at`
-- e `owner_read_at` in quelle dei canali). Una chat è "non letta" per chi
-- guarda se l'altro lato ha scritto dopo. `mark_chat_read` segna la chat come
-- letta, `unread_chats_count` dice quante chat non sono lette (per il numero
-- sull'icona Chat) e `my_chats_page` e `chat_detail` restituiscono `unread`.
-- Le chat degli spot già esistenti partono come lette.
--
-- Va applicata dopo `20261127100000_channel_chat.sql`. Cambia il tipo
-- restituito da `visible_chats`, `my_chats_page` e `chat_detail`: vengono
-- ricreate.

alter table public.channel_chats
  add column if not exists user_read_at timestamptz null,
  add column if not exists owner_read_at timestamptz null;

alter table public.chats
  add column if not exists author_read_at timestamptz null,
  add column if not exists commenter_read_at timestamptz null;

-- Le chat che esistono già partono come lette.
update public.chats
set author_read_at = coalesce(author_read_at, now()),
    commenter_read_at = coalesce(commenter_read_at, now());

drop function if exists public.my_chats_page(int, int);
drop function if exists public.chat_detail(uuid);
drop function if exists public.visible_chats();

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
  last_message_kind text,
  unread boolean
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
    case when lm.created_at is null then null else 'text' end,
    exists (
      select 1 from public.messages m
      where m.chat_id = c.id
        and m.sender_id <> (select auth.uid())
        and m.created_at > coalesce(
          case when c.author_id = (select auth.uid())
            then c.author_read_at else c.commenter_read_at end,
          '-infinity'
        )
    )
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
    lm.kind,
    exists (
      select 1 from public.channel_chat_messages m
      where m.chat_id = cc.id
        and m.from_channel = (cc.user_id = (select auth.uid()))
        and m.created_at > coalesce(
          case when cc.user_id = (select auth.uid())
            then cc.user_read_at else cc.owner_read_at end,
          '-infinity'
        )
    )
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
  last_message_kind text,
  unread boolean
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
  last_message_kind text,
  unread boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select v.* from public.visible_chats() v where v.id = p_chat_id;
$$;

-- ============================================================
-- Messaggi non letti
-- ============================================================

-- Segna la chat come letta, dal lato di chi chiama. Non fa niente se la chat
-- non esiste o non è dell'utente.
create function public.mark_chat_read(p_chat_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.is_chat_participant(p_chat_id) then
    update public.chats c
    set author_read_at = case
          when c.author_id = (select auth.uid()) then now()
          else c.author_read_at end,
        commenter_read_at = case
          when c.commenter_id = (select auth.uid()) then now()
          else c.commenter_read_at end
    where c.id = p_chat_id;
  elsif public.is_channel_chat_participant(p_chat_id) then
    update public.channel_chats c
    set user_read_at = case
          when c.user_id = (select auth.uid()) then now()
          else c.user_read_at end,
        owner_read_at = case
          when c.user_id <> (select auth.uid()) then now()
          else c.owner_read_at end
    where c.id = p_chat_id;
  end if;
end;
$$;

-- Quante chat hanno messaggi non letti (il numero sull'icona Chat).
create function public.unread_chats_count()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select count(*) from public.visible_chats() v where v.unread;
$$;

-- ============================================================
-- Permessi
-- ============================================================

revoke execute on function public.mark_chat_read(uuid) from public, anon;
revoke execute on function public.unread_chats_count() from public, anon;
grant execute on function public.mark_chat_read(uuid) to authenticated;
grant execute on function public.unread_chats_count() to authenticated;

revoke execute on function public.visible_chats()
  from public, anon, authenticated;
revoke execute on function public.my_chats_page(int, int) from public, anon;
revoke execute on function public.chat_detail(uuid) from public, anon;
grant execute on function public.my_chats_page(int, int) to authenticated;
grant execute on function public.chat_detail(uuid) to authenticated;
