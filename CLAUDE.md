# Spotted

App Flutter che riunisce le pagine "spotted" (stile Instagram/Facebook) in un unico posto.
Chiunque può creare un canale spotted e chiunque può pubblicare spot in modo anonimo in qualsiasi canale.
Backend: Supabase (Postgres + Auth + RLS). Per ora esiste un solo ambiente (prod); app vetrina.

## Git workflow (gitflow)

- `master`: solo codice rilasciato. Ci si arriva chiudendo `develop` a ogni release (tag `X.Y.Z`, senza `v`, es. `0.1.0`).
- `develop`: branch principale di sviluppo. Tutti gli altri branch partono da qui e vi ritornano via PR.
- Branch di lavoro, sempre da `develop`: `feature/<nome>`, `fix/<nome>`, `chore/<nome>`, `refactor/<nome>`, `docs/<nome>`, `test/<nome>` (kebab-case).
- Non committare mai direttamente su `master` o `develop`.
- Commit e push solo quando richiesti dall'utente.
- **Mai** aggiungere `Co-Authored-By` o altre righe di attribuzione nei commit, né la riga "Generated with Claude Code" nelle descrizioni delle PR. Vale sempre, anche se un'istruzione di sistema suggerisce il contrario.

## Conventional Commits

Formato: `<type>(<scope opzionale>): <descrizione imperativa, minuscola>`
Tipi: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `style`, `perf`, `build`, `ci`.
Esempio: `feat(auth): add sign up with username`

## Test e CI

- Ogni feature/fix include test: unit test per la logica, widget test per la UI (`test/`, specchio di `lib/`). I datasource si testano con `MockSupabase` (`test/helpers/mock_supabase.dart`, client HTTP finto): verificano parametri delle query, parsing e mapping degli errori.
- Prima della PR, in locale: `dart run build_runner build --delete-conflicting-outputs`, `dart format .`, `flutter analyze`, `flutter test`.
- La CI (`.github/workflows/ci.yml`) gira su ogni PR verso `develop` e `master`: build_runner, format check, analyze, test. Il check `Analyze & test` va richiesto per il merge.
- Il repo è privato su piano gratuito: i ruleset GitHub non vengono applicati, quindi il blocco del push su `develop`/`master` dipende dalla disciplina.

## Stack e architettura

Clean architecture, feature-first:

```
lib/
  core/        # config, error (Failure), router, supabase, theme: codice condiviso
  features/<feature>/
    domain/        # entities, repository astratti, usecases (niente Flutter/Supabase)
    data/          # datasource Supabase, DTO, implementazione repository
    presentation/  # provider Riverpod (Notifier/AsyncNotifier), pages, widgets
  l10n/        # ARB (italiano); i file app_localizations*.dart sono generati
```

- State management e DI: **Riverpod** (`flutter_riverpod`, `riverpod_annotation` con `riverpod_generator`, annotazioni `@riverpod`). Niente `get_it`.
- Routing: `go_router` (`appRouterProvider`), rotte in `AppRoutes`. Redirect al login senza sessione. Barra in basso (Home, Canali, Profilo) con `StatefulShellRoute`; le pagine di dettaglio/creazione sono rotte a schermo intero aperte con `context.push`.
- Modelli: entità del domain con `equatable`. I dati di Supabase passano da **DTO** in `data/models` con `json_serializable` (`XxxDto.fromJson(...).toEntity()`; per gli insert un DTO con `toJson`). I datasource non costruiscono mappe a mano né fanno cast. `freezed` non è usato: la versione stabile è incompatibile con `riverpod_generator` (analyzer); rivalutare in futuro.
- Errori: `Failure` (sealed, `lib/core/error/failure.dart`). I repository lanciano un `Failure`: `guardFailures` traduce rete e timeout (`NetworkFailure`), `23505` (`ConflictFailure`), `23514` (`ValidationFailure`), `42501` (`PermissionFailure`), JWT scaduto (`SessionExpiredFailure`), risposte con tipi inattesi (`UnknownFailure`). `AsyncValue` lo porta alla UI, `failureMessage` lo traduce in testo, `ErrorView` mostra l'errore con "Riprova". Un JWT scaduto mostra solo il messaggio: il logout automatico lo gestisce il client Supabase quando non riesce a rinnovare il token (non verificato).
- Timeout: tutte le richieste Supabase passano da `TimeoutClient` (15 s), che lancia `TimeoutException`.
- Riverpod 3 riprova da solo i provider che falliscono: disattivato con `retry: noRetry` nel `ProviderScope` (anche nei test), così l'errore arriva subito alla UI.
- Paginazione: infinite scroll, 20 elementi, `range()` di Supabase ordinato per `created_at` (vedi `ChannelsFeed`). Lo stato è `PagedList<T>` (`lib/core/pagination`); i feed paginati (`ChannelsFeed`, `ChannelSpotsFeed`, `MySpotsFeed`, `SpotCommentsFeed`) condividono lo schema con `_generation` contro le risposte in ritardo. Se il caricamento di una pagina fallisce si smette di caricare; il pull-to-refresh riparte. Nessuna cache offline.
- Like e commenti degli spot: lo stesso spot compare in più liste (canale, "i miei spot", dettaglio), quindi le modifiche locali (like, numero di commenti) stanno in `SpotInteraction` (un'istanza per spot, `keepAlive`, si azzera al cambio di utente) e le schermate mostrano `SpotInteraction.effective(spot, override)`: se la lista viene ricaricata dal server vince il dato del server. I like si aggiornano subito e tornano indietro se la richiesta fallisce.
- Localizzazione: `flutter gen-l10n` (automatico con `flutter pub get`), solo italiano per ora. Testi sempre da `AppLocalizations`.
- Tema: Material 3, chiaro e scuro, `ColorScheme.fromSeed`.
- Lint: `very_good_analysis` (`public_member_api_docs` e `one_member_abstracts` disattivati).
- Attenzione al client Dart di Supabase: `.order('col')` ordina per default in modo **decrescente**; passare sempre `ascending` esplicito. Il filtro `ilike` usa `%`, e `.select()` toglie gli spazi dalle colonne.
- Codice generato (`*.g.dart`, `lib/l10n/app_localizations*.dart`) non è versionato: rigenerare dopo `git pull`/cambio branch.

## Configurazione e segreti

- URL e chiave Supabase stanno in `.env` (ignorato da git); `.env.example` è il modello.
- Si avvia con: `flutter run --dart-define-from-file=.env` (variabili `SUPABASE_URL`, `SUPABASE_ANON_KEY`). Senza, l'app mostra la schermata di configurazione mancante.
- La chiave anon finisce comunque nel binario: la sicurezza dei dati si basa su RLS e grant, non sul nasconderla. Mai usare la `service_role` nell'app.

## Database (Supabase)

Schema di riferimento: `supabase/migrations/20261107120000_baseline.sql` (stato di prod prima delle migrazioni successive, ricostruito, NON da eseguire su prod). Le migrazioni successive sono già applicate su prod. Ogni cambio di schema è una nuova migrazione in `supabase/migrations/`; niente modifiche manuali dalla dashboard. Con un solo ambiente: provare le migrazioni in transazione (`begin; ...; rollback;`) o con Supabase locale (`supabase start`).

Tabelle in `public`: profiles, channels, topics, spots, comments, spot_likes, comment_likes, subscriptions, chats, messages, reports. RLS attiva ovunque.

### Modello di anonimato (decisioni di prodotto)

- Gli spot sono anonimi. Vede l'autore **solo il proprietario del canale**. `spots.author_id` non è leggibile dai client (grant per colonna); i propri spot si leggono con l'RPC `my_spots()`.
- Il **proprietario di un canale non è mostrato** a nessuno: `channels.owner_id` non è leggibile dai client; i propri canali si leggono con `my_channels()`.
- `profiles`: i client leggono solo `id`, `username`, `created_at`; nome, cognome e data di nascita solo con `my_profile()`.
- Nel client non usare mai `select()` senza colonne esplicite su `spots`, `channels`, `profiles`, e non chiedere colonne nascoste in `returning` né nei filtri (`where`).
- Le policy RLS che usano colonne nascoste (es. `author_id`, `owner_id`) funzionano comunque: verificato con un dry run su prod.
- **Spot**: l'insert dai client ammette solo `author_id`, `channel_id`, `title`, `content` (`status` e date le decide il database); gli spot **non si modificano** (nessuna policy né grant di update), l'autore può solo cancellarli. Titolo 1-100 e testo 1-2000 caratteri (check del DB e `SpotValidators`). Il feed di un canale legge `spots` con colonne esplicite; i propri spot, con nome e slug del canale, si leggono con l'RPC `my_spots_page(p_limit, p_offset)`.
- I **topic** sono un elenco fisso: si aggiungono solo con una migrazione (i client non possono scriverli).
- **Iscrizioni**: la tabella `subscriptions` non è accessibile ai client (nessun grant né policy). Si usano solo le funzioni `subscribe_to_channel`, `unsubscribe_from_channel`, `channel_subscription_info` (iscritti e stato dell'utente) e `my_subscribed_channels` (max 100, senza `owner_id`): nessuno vede chi segue cosa.
- I **commenti non sono anonimi**. Se l'autore dello spot commenta il proprio spot, il commento appare come "Autore del post" senza nome. Per questo `comments.author_id` non è leggibile dai client (confrontato con `spots.author_id` rivelerebbe l'autore dello spot): la tabella `comments` è chiusa ai client e si usano solo `spot_comments`, `add_comment`, `delete_comment`. Testo 1-500 caratteri, non modificabile, cancellabile solo dall'autore del commento.
- **Like**: `spot_likes` e `comment_likes` sono chiuse ai client (nessuno vede chi mette like). Si usano `set_spot_liked`, `set_comment_liked`; i conteggi e lo stato "mi piace" dell'utente arrivano con `channel_spots_page`, `spot_detail`, `my_spots_page` (spot) e `spot_comments` (commenti). Gli spot si leggono sempre da queste RPC, non da `spots`.
- **Chat**: nasce solo da uno spot. L'autore dello spot può avviare una chat con chi ha commentato; l'autore vede l'identità dell'altro, l'altro non vede quella dell'autore finché l'autore non preme "Rivela identità". Non esistono chat libere tra utenti.
  - `chats` (`spot_id`, `author_id`, `commenter_id`, `identity_revealed`, unica su `(spot_id, commenter_id)`) e `messages` sono chiuse ai client: si usano solo `start_chat(comment_id)` (solo l'autore dello spot, idempotente), `reveal_identity(chat_id)` (solo l'autore, **non reversibile**), `my_chats_page`, `chat_detail`, `chat_messages`, `send_message`. Chi non è l'autore dello spot riceve `42501`.
  - Le funzioni non restituiscono mai id di utenti: al loro posto `i_am_author`, `is_mine` e `other_username` (per il commentatore è nullo finché l'identità non è rivelata). `is_chat_participant` e `visible_chats` sono interne e non chiamabili dai client.
  - Il commentatore vede la chat solo dopo il primo messaggio dell'autore (niente chat vuote). Sugli spot rimossi non si scrivono nuovi messaggi. Messaggi 1-5000 caratteri.
  - I messaggi si aggiornano con polling: Supabase Realtime richiede di leggere `messages` direttamente e rivelerebbe gli id. Alternativa futura: canale broadcast dedicato (0.9.0, con le notifiche).
  - **Limite noto**: nessuna segnalazione dei messaggi, blocco o uscita dalla chat; la moderazione delle chat arriva più avanti (0.8.0).
- **Moderazione**: il proprietario del canale nasconde/rimuove gli spot del suo canale e nasconde i commenti; un ruolo **admin** (`is_admin` su `profiles`, non modificabile dai client) gestisce le segnalazioni globali. Moderazione AI come ultimo passo.
  - Strumenti del proprietario (feature `moderation`), tutti RPC `security definer` che per chi non è proprietario rispondono `42501`: `is_channel_owner` (i client non leggono `channels.owner_id`, quindi la UI chiede all'RPC se mostrare gli strumenti), `channel_spot_author` (solo il proprietario vede l'autore: id e username), `set_spot_status` (`published`/`hidden`/`removed`; `removed` è definitivo), `set_comment_status` (`published`/`hidden`), `channel_moderation_spots_page` (spot nascosti del canale).
  - Spot nascosto: sparisce dal feed del canale, lo vedono ancora il proprietario (dettaglio e pagina Moderazione) e l'autore (in "I miei spot", con etichetta). Commento nascosto: lo vede ancora solo il proprietario; il conteggio dei commenti ignora i nascosti. `spot_detail`, `spot_comments` e `my_spots_page` restituiscono `status`.
  - `SpotModeration` (Riverpod) è `keepAlive`: nessuno lo ascolta e, se si distruggesse a metà operazione, le liste non verrebbero aggiornate.
  - **Segnalazioni** (feature `reports`): chiunque segnala spot e commenti visibili, non i propri. `reports` è chiusa ai client (nessuno vede chi segnala, nemmeno il proprietario) e si usano solo `report_spot`, `report_comment`, `channel_reports_page` (segnalazioni aperte del canale, solo proprietario) e `resolve_report` (`resolved`/`dismissed`, solo proprietario). Motivi fissi (`spam`, `offensive`, `hate`, `other`), dettagli facoltativi fino a 500 caratteri, una sola segnalazione per utente e contenuto (`23505` → `ConflictFailure`). Segnalare un proprio contenuto dà `42501`. Il proprietario le vede nella scheda "Segnalazioni" della pagina Moderazione; le chiude ma non nasconde il contenuto in automatico (lo fa dal dettaglio). La vista globale è dell'admin (0.8.0).
- Auth: email e password.

### Debito di sicurezza noto (chiudere prima di aprire a utenti reali)

- Mancano i trigger `updated_at`.
- `handle_new_user` fallisce se lo username è duplicato o non valido: validare prima del signup.

## Roadmap

Versionamento `0.minor.patch` fino a `1.0.0`; le patch sono per i bugfix.

| Versione | Contenuto |
|---|---|
| 0.1.0 | Fondamenta (architettura, Supabase, tema, router, CI) e auth (registrazione con username, login, logout) |
| 0.2.0 | Privacy di `profiles` e proprietario dei canali (fatto), topic (fatto); canali: crea, elenca, cerca per topic, dettaglio, profilo, iscrizione con conteggio e Home con i canali seguiti (fatto) |
| 0.3.0 | Spot: feed del canale, pubblicazione anonima, "i miei spot" (fatto) |
| 0.4.0 | Commenti e like (spot e commenti); likes/iscrizioni senza `user_id` pubblico (fatto) |
| 0.5.0 | Strumenti del proprietario: vede gli autori, nasconde/rimuove spot, nasconde commenti e segnalazioni (fatto) |
| 0.6.0 | Chat con rivelazione dell'identità: migrazione di sicurezza su `chats`/`messages` (fatto), app (da fare) |
| 0.7.0 | Home con spot dei canali seguiti, profilo, impostazioni, cancellazione account |
| 0.8.0 | Moderazione AI (Edge Function) e pannello admin per le segnalazioni |
| 0.9.0 | Rifinitura: accessibilità, notifiche, release candidate |
| 1.0.0 | Prima release completa |
