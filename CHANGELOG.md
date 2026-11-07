# Changelog

Formato basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).
Versionamento `0.minor.patch` fino alla `1.0.0`.

## [0.1.0] - 2026-11-07

### Aggiunto
- Struttura clean architecture feature-first (`lib/core`, `lib/features`).
- Stack: Riverpod, `go_router`, `supabase_flutter`, `equatable`, `json_serializable`, `very_good_analysis`.
- Bootstrap Supabase con configurazione da `--dart-define-from-file=.env` e schermata di configurazione mancante.
- Tema Material 3 chiaro e scuro, localizzazione in italiano.
- Autenticazione con email e password: registrazione (nome, cognome, username, email, password), login, logout, redirect del router in base alla sessione.
- CI GitHub Actions su ogni PR: `build_runner`, format, analyze, test.
- Schema di riferimento del database in `supabase/migrations/`.
