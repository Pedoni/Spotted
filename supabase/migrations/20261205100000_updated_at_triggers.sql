-- Trigger `updated_at` (#72).
--
-- Le tabelle `spots` e `comments` hanno `updated_at`, ma nessuno lo
-- aggiornava: restava per sempre quello della creazione. Ora un trigger lo
-- porta all'ora della modifica a ogni `update` della riga (per esempio quando
-- il proprietario pubblica, rifiuta o nasconde uno spot, o nasconde un
-- commento).
--
-- Sono le uniche due tabelle con `updated_at` (controllato su tutte le
-- migrazioni): se una tabella nuova ne avrà uno, userà la stessa funzione.
--
-- Il client non può falsificarlo: le due tabelle non si aggiornano
-- direttamente (nessun permesso di `update`), si passa da funzioni che il
-- trigger comunque sovrascrive.

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function public.set_updated_at()
  from public, anon, authenticated;

create trigger spots_set_updated_at
  before update on public.spots
  for each row execute function public.set_updated_at();

create trigger comments_set_updated_at
  before update on public.comments
  for each row execute function public.set_updated_at();
