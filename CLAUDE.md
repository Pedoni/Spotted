# Spotted

App Flutter che riunisce le pagine "spotted" (stile Instagram/Facebook) in un unico posto.
Chiunque può creare un canale spotted e chiunque può pubblicare spot in modo anonimo in qualsiasi canale.
Backend: Supabase (Postgres + Auth + RLS).

## Git workflow (gitflow)

- `master`: solo codice rilasciato. Ci si arriva chiudendo `develop` a ogni release.
- `develop`: branch principale di sviluppo. Tutti gli altri branch partono da qui e vi ritornano.
- Branch di lavoro, sempre da `develop`: `feature/<nome>`, `fix/<nome>`, `chore/<nome>`, `refactor/<nome>`, `docs/<nome>`, `test/<nome>` (nomi in kebab-case).
- Non committare mai direttamente su `master` o `develop`.
- Commit solo quando richiesto dall'utente.

## Conventional Commits

Formato: `<type>(<scope opzionale>): <descrizione imperativa, minuscola>`
Tipi: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `style`, `perf`, `build`, `ci`.
Esempio: `feat(auth): add sign up with username`

## Test e CI

- Ogni feature/fix include test: unit test per la logica, widget test per la UI (`test/`, specchio di `lib/`).
- Prima di aprire la PR eseguire in locale: `dart format .`, `flutter analyze`, `flutter test`.
- La CI (`.github/workflows/ci.yml`) gira su ogni PR verso `develop` e `master`: format check, analyze, test. Il check `Analyze & test` è obbligatorio per il merge.
- `develop` e `master` sono protetti: si cambia solo via PR con CI verde, mai con push diretto.

## Segreti

- URL e anon key di Supabase stanno in `.env` (mai committato). Va in `.gitignore`; mantenere un `.env.example` senza valori.
- La anon key finisce comunque nel binario dell'app: la sicurezza dei dati si basa su RLS e grant, non sul nasconderla.

## Database (Supabase)

Tabelle in `public`: profiles, channels, topics, spots, comments, spot_likes, comment_likes, subscriptions, chats, messages, reports. RLS attiva ovunque.

- Anonimato: `spots.author_id` non è leggibile dai client (grant per colonna, `select` esplicito). I propri spot si leggono con l'RPC `my_spots()`. Nel client Flutter non usare mai `select()` senza colonne esplicite.
- `chats` richiede `user_a_id < user_b_id`: ordinare gli id prima dell'insert.
- `handle_new_user` crea il profilo alla registrazione; lo username deve rispettare `^[a-zA-Z0-9_]{3,30}$` ed essere univoco (controllare prima del signup).
- Debito noto, da chiudere prima di aprire a utenti reali: anonimato di `comments`, restrizione di `profiles` (nome, cognome, data di nascita pubblici), `user_id` esposto in likes/subscriptions, moderazione degli spot, trigger `updated_at`.
