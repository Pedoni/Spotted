-- L'utente corrente è l'autore dello spot (0.6.0, parte 2).
--
-- Serve alla UI per mostrare "Chatta" sui commenti solo all'autore dello spot:
-- `spots.author_id` non è leggibile dai client. La funzione risponde solo
-- riguardo a chi chiama, quindi non rivela l'autore a nessun altro.

create or replace function public.is_spot_author(p_spot_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.spots s
    where s.id = p_spot_id and s.author_id = (select auth.uid())
  );
$$;

revoke execute on function public.is_spot_author(uuid) from public, anon;
grant execute on function public.is_spot_author(uuid) to authenticated;
