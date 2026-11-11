# Spotted

App Flutter che riunisce le pagine "spotted" in un unico posto: chiunque può creare un canale e chiunque può pubblicare spot in modo anonimo in qualsiasi canale. Backend su Supabase.

Convenzioni di progetto, architettura e roadmap: [CLAUDE.md](CLAUDE.md). Storico delle versioni: [CHANGELOG.md](CHANGELOG.md).

## Requisiti

- Flutter 3.47.9 (stable) e Dart ^3.12.2
- Un progetto Supabase con lo schema di `supabase/migrations/`

## Avvio

1. Copia `.env.example` in `.env` e inserisci `SUPABASE_URL` e `SUPABASE_ANON_KEY` (Supabase → Project Settings → API).
2. Installa le dipendenze e genera il codice (Riverpod e localizzazioni):
   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Avvia l'app:
   ```bash
   flutter run --dart-define-from-file=.env
   ```
   In VS Code basta F5 sulla configurazione "spotted (debug)".

Il codice generato (`*.g.dart`, `app_localizations*.dart`) non è versionato: va rigenerato dopo un clone o un cambio di branch. Durante lo sviluppo si può lasciare attivo `dart run build_runner watch --delete-conflicting-outputs`.

## Test

```bash
dart format .
flutter analyze
flutter test
```

La stessa sequenza gira in CI su ogni pull request.

## Workflow

Gitflow con conventional commits: i branch di lavoro partono da `develop` e tornano con una PR; `master` contiene solo le release. Dettagli in [CLAUDE.md](CLAUDE.md).
