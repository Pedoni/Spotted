-- Privacy di profili e canali.
--
-- profiles: nome, cognome e data di nascita non sono più leggibili dai client.
--           Restano pubblici id, username, created_at. I dati completi si leggono
--           con my_profile().
-- channels: owner_id non è leggibile dai client (il proprietario non è mostrato).
--           I propri canali si leggono con my_channels().
--
-- Nota per il client: non fare mai select() senza colonne esplicite su queste
-- tabelle, e non chiedere colonne nascoste in `returning`.

-- ============================================================
-- profiles
-- ============================================================

revoke select on public.profiles from anon, authenticated;
grant select (id, username, created_at) on public.profiles to anon, authenticated;

create or replace function public.my_profile()
returns setof public.profiles
language sql
security definer
set search_path = ''
as $$
  select * from public.profiles where id = (select auth.uid());
$$;

revoke execute on function public.my_profile() from public, anon;
grant execute on function public.my_profile() to authenticated;

-- ============================================================
-- channels
-- ============================================================

revoke select on public.channels from anon, authenticated;
grant select (id, topic_id, name, slug, description, place, created_at)
  on public.channels to anon, authenticated;

create or replace function public.my_channels()
returns setof public.channels
language sql
security definer
set search_path = ''
as $$
  select * from public.channels
  where owner_id = (select auth.uid())
  order by created_at desc;
$$;

revoke execute on function public.my_channels() from public, anon;
grant execute on function public.my_channels() to authenticated;
