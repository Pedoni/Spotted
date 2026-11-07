-- ATTENZIONE: questo file descrive lo stato GIÀ presente in prod. Non eseguirlo su prod
-- (le tabelle esistono già). Serve come riferimento e per creare un database da zero
-- (es. Supabase locale con `supabase start`). Ricostruito, non estratto con pg_dump.
--
-- Baseline dello schema `public`, ricostruito dallo stato di prod al 2026-11-07.
-- Contiene: tabelle, indici, RLS, policy, handle_new_user + trigger su auth.users,
-- grant per colonna su spots (anonimato dell'autore) e my_spots().

-- ============================================================
-- Tabelle
-- ============================================================

create table public.topics (
  id uuid not null default gen_random_uuid(),
  name text not null,
  description text null,
  constraint topics_pkey primary key (id),
  constraint topics_name_key unique (name)
);

create table public.profiles (
  id uuid not null,
  username text not null,
  first_name text null,
  last_name text null,
  birth_date date null,
  created_at timestamptz not null default now(),
  constraint profiles_pkey primary key (id),
  constraint profiles_username_key unique (username),
  constraint profiles_id_fkey foreign key (id) references auth.users (id) on delete cascade,
  constraint profiles_username_check check (username ~ '^[a-zA-Z0-9_]{3,30}$')
);

create table public.channels (
  id uuid not null default gen_random_uuid(),
  owner_id uuid not null,
  topic_id uuid null,
  name text not null,
  slug text not null,
  description text null,
  place text null,
  created_at timestamptz not null default now(),
  constraint channels_pkey primary key (id),
  constraint channels_slug_key unique (slug),
  constraint channels_owner_id_fkey foreign key (owner_id) references public.profiles (id),
  constraint channels_topic_id_fkey foreign key (topic_id) references public.topics (id) on delete set null
);

create table public.spots (
  id uuid not null default gen_random_uuid(),
  author_id uuid not null,
  channel_id uuid not null,
  title text not null,
  content text not null,
  status text not null default 'published',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint spots_pkey primary key (id),
  constraint spots_author_id_fkey foreign key (author_id) references public.profiles (id),
  constraint spots_channel_id_fkey foreign key (channel_id) references public.channels (id) on delete cascade,
  constraint spots_status_check check (status = any (array['published', 'hidden', 'removed']))
);

create index if not exists spots_channel_created_idx on public.spots using btree (channel_id, created_at desc);
create index if not exists spots_author_idx on public.spots using btree (author_id);

create table public.comments (
  id uuid not null default gen_random_uuid(),
  author_id uuid not null,
  spot_id uuid not null,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint comments_pkey primary key (id),
  constraint comments_author_id_fkey foreign key (author_id) references public.profiles (id),
  constraint comments_spot_id_fkey foreign key (spot_id) references public.spots (id) on delete cascade
);

create index if not exists comments_spot_created_idx on public.comments using btree (spot_id, created_at);

create table public.spot_likes (
  user_id uuid not null,
  spot_id uuid not null,
  created_at timestamptz not null default now(),
  constraint spot_likes_pkey primary key (user_id, spot_id),
  constraint spot_likes_spot_id_fkey foreign key (spot_id) references public.spots (id) on delete cascade,
  constraint spot_likes_user_id_fkey foreign key (user_id) references public.profiles (id) on delete cascade
);

create table public.comment_likes (
  user_id uuid not null,
  comment_id uuid not null,
  created_at timestamptz not null default now(),
  constraint comment_likes_pkey primary key (user_id, comment_id),
  constraint comment_likes_comment_id_fkey foreign key (comment_id) references public.comments (id) on delete cascade,
  constraint comment_likes_user_id_fkey foreign key (user_id) references public.profiles (id) on delete cascade
);

create table public.subscriptions (
  user_id uuid not null,
  channel_id uuid not null,
  created_at timestamptz not null default now(),
  constraint subscriptions_pkey primary key (user_id, channel_id),
  constraint subscriptions_channel_id_fkey foreign key (channel_id) references public.channels (id) on delete cascade,
  constraint subscriptions_user_id_fkey foreign key (user_id) references public.profiles (id) on delete cascade
);

create index if not exists subscriptions_channel_idx on public.subscriptions using btree (channel_id);

create table public.chats (
  id uuid not null default gen_random_uuid(),
  user_a_id uuid not null,
  user_b_id uuid not null,
  created_at timestamptz not null default now(),
  constraint chats_pkey primary key (id),
  constraint chats_user_a_id_user_b_id_key unique (user_a_id, user_b_id),
  constraint chats_user_a_id_fkey foreign key (user_a_id) references public.profiles (id) on delete cascade,
  constraint chats_user_b_id_fkey foreign key (user_b_id) references public.profiles (id) on delete cascade,
  constraint chats_check check (user_a_id < user_b_id)
);

create table public.messages (
  id uuid not null default gen_random_uuid(),
  chat_id uuid not null,
  sender_id uuid not null,
  content text not null,
  created_at timestamptz not null default now(),
  constraint messages_pkey primary key (id),
  constraint messages_chat_id_fkey foreign key (chat_id) references public.chats (id) on delete cascade,
  constraint messages_sender_id_fkey foreign key (sender_id) references public.profiles (id),
  constraint messages_content_check check (length(content) >= 1 and length(content) <= 5000)
);

create index if not exists messages_chat_created_idx on public.messages using btree (chat_id, created_at);

create table public.reports (
  id uuid not null default gen_random_uuid(),
  reporter_id uuid not null,
  spot_id uuid null,
  comment_id uuid null,
  reason text not null,
  details text null,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  constraint reports_pkey primary key (id),
  constraint reports_comment_id_fkey foreign key (comment_id) references public.comments (id) on delete cascade,
  constraint reports_reporter_id_fkey foreign key (reporter_id) references public.profiles (id) on delete cascade,
  constraint reports_spot_id_fkey foreign key (spot_id) references public.spots (id) on delete cascade,
  constraint reports_check check (
    (spot_id is not null and comment_id is null)
    or (spot_id is null and comment_id is not null)
  ),
  constraint reports_status_check check (
    status = any (array['open', 'reviewing', 'resolved', 'dismissed'])
  )
);

create index if not exists reports_status_created_idx on public.reports using btree (status, created_at);

-- ============================================================
-- Registrazione: creazione automatica del profilo
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
declare
  chosen_username text;
begin
  chosen_username := lower(
    coalesce(
      new.raw_user_meta_data ->> 'username',
      'user_' || replace(new.id::text, '-', '')
    )
  );

  insert into public.profiles (id, username, first_name, last_name)
  values (
    new.id,
    chosen_username,
    new.raw_user_meta_data ->> 'first_name',
    new.raw_user_meta_data ->> 'last_name'
  );

  return new;
end;
$function$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- Row Level Security
-- ============================================================

alter table public.topics        enable row level security;
alter table public.profiles      enable row level security;
alter table public.channels      enable row level security;
alter table public.spots         enable row level security;
alter table public.comments      enable row level security;
alter table public.spot_likes    enable row level security;
alter table public.comment_likes enable row level security;
alter table public.subscriptions enable row level security;
alter table public.chats         enable row level security;
alter table public.messages      enable row level security;
alter table public.reports       enable row level security;

-- profiles
create policy "Profiles are publicly readable" on public.profiles
  for select to anon, authenticated using (true);
create policy "Users update their own profile" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- topics
create policy "Topics readable by everyone" on public.topics
  for select to anon, authenticated using (true);

-- channels
create policy "Channels readable by everyone" on public.channels
  for select to anon, authenticated using (true);
create policy "Authenticated users create channels" on public.channels
  for insert to authenticated with check (owner_id = (select auth.uid()));
create policy "Owners update their channels" on public.channels
  for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
create policy "Owners delete their channels" on public.channels
  for delete to authenticated using (owner_id = (select auth.uid()));

-- subscriptions
create policy "Read subscription counts" on public.subscriptions
  for select to anon, authenticated using (true);
create policy "Subscribe as yourself" on public.subscriptions
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy "Unsubscribe as yourself" on public.subscriptions
  for delete to authenticated using (user_id = (select auth.uid()));

-- spots
create policy "Read published spots" on public.spots
  for select to anon, authenticated using (status = 'published');
create policy "Authenticated users create their own spots" on public.spots
  for insert to authenticated with check (author_id = (select auth.uid()));
create policy "Authors update their own spots" on public.spots
  for update to authenticated
  using (author_id = (select auth.uid()) and status = 'published')
  with check (author_id = (select auth.uid()) and status = 'published');
create policy "Authors delete their own spots" on public.spots
  for delete to authenticated using (author_id = (select auth.uid()));

-- comments
create policy "Read comments on published spots" on public.comments
  for select to anon, authenticated
  using (exists (
    select 1 from public.spots s
    where s.id = comments.spot_id and s.status = 'published'
  ));
create policy "Authenticated users create comments" on public.comments
  for insert to authenticated
  with check (
    author_id = (select auth.uid())
    and exists (
      select 1 from public.spots s
      where s.id = comments.spot_id and s.status = 'published'
    )
  );
create policy "Authors update their comments" on public.comments
  for update to authenticated
  using (author_id = (select auth.uid()))
  with check (author_id = (select auth.uid()));
create policy "Authors delete their comments" on public.comments
  for delete to authenticated using (author_id = (select auth.uid()));

-- spot_likes
create policy "Read likes on published spots" on public.spot_likes
  for select to anon, authenticated
  using (exists (
    select 1 from public.spots s
    where s.id = spot_likes.spot_id and s.status = 'published'
  ));
create policy "Like as yourself" on public.spot_likes
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.spots s
      where s.id = spot_likes.spot_id and s.status = 'published'
    )
  );
create policy "Remove your own likes" on public.spot_likes
  for delete to authenticated using (user_id = (select auth.uid()));

-- comment_likes
create policy "Read comment likes" on public.comment_likes
  for select to anon, authenticated
  using (exists (
    select 1 from public.comments c
    join public.spots s on s.id = c.spot_id
    where c.id = comment_likes.comment_id and s.status = 'published'
  ));
create policy "Like comments as yourself" on public.comment_likes
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.comments c
      join public.spots s on s.id = c.spot_id
      where c.id = comment_likes.comment_id and s.status = 'published'
    )
  );
create policy "Remove your comment likes" on public.comment_likes
  for delete to authenticated using (user_id = (select auth.uid()));

-- chats
create policy "Participants read their chats" on public.chats
  for select to authenticated
  using ((select auth.uid()) = user_a_id or (select auth.uid()) = user_b_id);
create policy "Users create chats they participate in" on public.chats
  for insert to authenticated
  with check (
    ((select auth.uid()) = user_a_id or (select auth.uid()) = user_b_id)
    and user_a_id <> user_b_id
  );

-- messages
create policy "Participants read messages" on public.messages
  for select to authenticated
  using (exists (
    select 1 from public.chats c
    where c.id = messages.chat_id
      and ((select auth.uid()) = c.user_a_id or (select auth.uid()) = c.user_b_id)
  ));
create policy "Participants send messages as themselves" on public.messages
  for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and exists (
      select 1 from public.chats c
      where c.id = messages.chat_id
        and ((select auth.uid()) = c.user_a_id or (select auth.uid()) = c.user_b_id)
    )
  );

-- reports
create policy "Users create their own reports" on public.reports
  for insert to authenticated with check (reporter_id = (select auth.uid()));
create policy "Users read their own reports" on public.reports
  for select to authenticated using (reporter_id = (select auth.uid()));

-- ============================================================
-- Anonimato degli spot: author_id non leggibile dai client
-- ============================================================

revoke select on public.spots from anon, authenticated;
grant select (id, channel_id, title, content, status, created_at, updated_at)
  on public.spots to anon, authenticated;

create or replace function public.my_spots()
returns setof public.spots
language sql
security definer
set search_path = ''
as $$
  select * from public.spots where author_id = (select auth.uid());
$$;

revoke execute on function public.my_spots() from public, anon;
grant execute on function public.my_spots() to authenticated;
