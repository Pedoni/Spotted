-- Scrittura dei canali solo dalle colonne consentite (0.8.0).
--
-- Da applicare DOPO l'aggiornamento dell'app: la versione precedente scriveva
-- `place` a mano e con questi permessi non potrebbe più creare canali.
--
-- Il luogo di un canale ora è un comune dell'elenco ufficiale: l'app manda solo
-- `municipality_id` e il trigger `channels_sync_municipality` calcola `place`,
-- `province_code` e `region_name`. Per far valere davvero il vincolo "niente
-- testo libero" i client non devono poter scrivere quelle colonne, quindi
-- l'insert è limitato alle colonne che l'app usa (come per `spots`).
--
-- Modificare ed eliminare un canale non si fa più direttamente sulla tabella:
-- la modifica e l'eliminazione da parte del proprietario passano da funzioni
-- dedicate (arrivano con la modifica del canale). Finché non ci sono, nessun
-- client può modificare o cancellare canali; l'app non lo fa.

revoke insert, update, delete on public.channels from anon, authenticated;

grant insert (owner_id, topic_id, name, slug, description, municipality_id)
  on public.channels to authenticated;
