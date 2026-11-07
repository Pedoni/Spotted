-- Privacy delle iscrizioni ai canali.
--
-- La tabella `subscriptions` non è più accessibile ai client: prima chiunque
-- poteva leggere `user_id` e sapere chi segue cosa. Ora si passa da funzioni
-- (security definer) che usano l'utente autenticato e non espongono mai gli id
-- degli iscritti:
--   subscribe_to_channel(channel_id)        segui un canale (idempotente)
--   unsubscribe_from_channel(channel_id)    smetti di seguirlo
--   channel_subscription_info(channel_id)   numero di iscritti e se sei iscritto
--   my_subscribed_channels()                i canali che segui (senza owner_id)

revoke all on public.subscriptions from anon, authenticated;

drop policy if exists "Read subscription counts" on public.subscriptions;
drop policy if exists "Subscribe as yourself" on public.subscriptions;
drop policy if exists "Unsubscribe as yourself" on public.subscriptions;

create or replace function public.subscribe_to_channel(p_channel_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.subscriptions (user_id, channel_id)
  values ((select auth.uid()), p_channel_id)
  on conflict do nothing;
$$;

create or replace function public.unsubscribe_from_channel(p_channel_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.subscriptions
  where user_id = (select auth.uid()) and channel_id = p_channel_id;
$$;

create or replace function public.channel_subscription_info(p_channel_id uuid)
returns table (subscriber_count bigint, is_subscribed boolean)
language sql
security definer
set search_path = ''
as $$
  select
    count(*)::bigint,
    coalesce(bool_or(user_id = (select auth.uid())), false)
  from public.subscriptions
  where channel_id = p_channel_id;
$$;

create or replace function public.my_subscribed_channels()
returns table (
  id uuid,
  topic_id uuid,
  name text,
  slug text,
  description text,
  place text,
  created_at timestamptz
)
language sql
security definer
set search_path = ''
as $$
  select c.id, c.topic_id, c.name, c.slug, c.description, c.place, c.created_at
  from public.subscriptions s
  join public.channels c on c.id = s.channel_id
  where s.user_id = (select auth.uid())
  order by s.created_at desc
  limit 100;
$$;

revoke execute on function public.subscribe_to_channel(uuid) from public, anon;
revoke execute on function public.unsubscribe_from_channel(uuid) from public, anon;
revoke execute on function public.channel_subscription_info(uuid) from public, anon;
revoke execute on function public.my_subscribed_channels() from public, anon;

grant execute on function public.subscribe_to_channel(uuid) to authenticated;
grant execute on function public.unsubscribe_from_channel(uuid) to authenticated;
grant execute on function public.channel_subscription_info(uuid) to authenticated;
grant execute on function public.my_subscribed_channels() to authenticated;
