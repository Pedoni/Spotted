-- Modifica dei propri dati (#62).
--
-- `update_my_profile(nome, cognome, data di nascita)` cambia i dati personali
-- dell'utente che chiama e restituisce il profilo aggiornato (come
-- `my_profile()`). **Lo username non si cambia mai**: i commenti, le chat e i
-- canali lo mostrano, e deve restare lo stesso nel tempo.
--
-- Regole (violarle dà `23514`): nome e cognome obbligatori, fino a 50
-- caratteri (come nella registrazione); la data di nascita è facoltativa, non
-- può essere nel futuro né prima del 1900-01-01.
--
-- Chiude un buco: la baseline lasciava a ogni utente un `update` diretto sulla
-- propria riga di `profiles` ("Users update their own profile"), quindi un
-- client poteva cambiare lo username o altro senza controlli. Ora il permesso
-- e la policy di `update` si tolgono: i dati si cambiano solo da qui.

revoke update on public.profiles from anon, authenticated;
drop policy if exists "Users update their own profile" on public.profiles;

create function public.update_my_profile(
  p_first_name text,
  p_last_name text,
  p_birth_date date
)
returns setof public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_first text := nullif(btrim(coalesce(p_first_name, '')), '');
  v_last text := nullif(btrim(coalesce(p_last_name, '')), '');
begin
  if (select auth.uid()) is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  if v_first is null or char_length(v_first) > 50 then
    raise exception 'invalid first name' using errcode = '23514';
  end if;
  if v_last is null or char_length(v_last) > 50 then
    raise exception 'invalid last name' using errcode = '23514';
  end if;
  if p_birth_date is not null
     and (p_birth_date > current_date or p_birth_date < date '1900-01-01') then
    raise exception 'invalid birth date' using errcode = '23514';
  end if;

  update public.profiles p
  set first_name = v_first,
      last_name = v_last,
      birth_date = p_birth_date
  where p.id = (select auth.uid());

  return query select * from public.profiles p where p.id = (select auth.uid());
end;
$$;

revoke execute on function public.update_my_profile(text, text, date)
  from public, anon;
grant execute on function public.update_my_profile(text, text, date)
  to authenticated;
