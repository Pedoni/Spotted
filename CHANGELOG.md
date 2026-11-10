# Changelog

Formato basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).
Versionamento `0.minor.patch` fino alla `1.0.0`.

## [0.3.0] - 2026-11-10

### Aggiunto
- Spot: feed di ogni canale (dal più recente, scorrimento infinito) nella pagina del canale.
- Pubblicazione di spot anonimi in qualsiasi canale, con titolo (max 100 caratteri) e testo (max 2000).
- "I miei spot" nel profilo, con il canale di ogni spot e cancellazione dopo conferma.

### Modificato
- Gli spot non si modificano: l'autore può solo cancellarli.
- Database: l'insert sugli spot accetta solo le colonne scrivibili, vincoli di lunghezza su titolo e testo, nuovo RPC `my_spots_page(limit, offset)`.
- Lo stato delle liste paginate è un `PagedList<T>` condiviso (canali, spot, miei spot).
- Un vincolo del database violato (es. testo troppo lungo) ora mostra "Controlla i dati inseriti".

## [0.2.0] - 2026-11-08

### Aggiunto
- Canali: lista con ricerca per nome e filtro per topic, scorrimento infinito, dettaglio, creazione (slug generato dal nome) e "i miei canali".
- Topic: elenco fisso (Università, Scuola, Città, Sport, Eventi, Musica, Lavoro).
- Iscrizioni: segui / smetti di seguire un canale, con il numero di iscritti.
- Home con i canali seguiti.
- Profilo con username, nome, cognome ed email, e logout.
- Barra di navigazione in basso (Home, Canali, Profilo).
- Messaggi per errori di permesso e sessione scaduta; timeout di 15 secondi sulle richieste.

### Modificato
- Privacy: nome, cognome e data di nascita non sono più leggibili dagli altri utenti; il proprietario di un canale non è mostrato; la tabella delle iscrizioni non è più accessibile ai client (nessuno vede chi segue cosa).
- I dati di Supabase sono letti con DTO (`json_serializable`) e testati con un client HTTP finto.
- Disattivati i retry automatici di Riverpod: gli errori arrivano subito alla UI con "Riprova".

### Corretto
- La lista dei canali non mescola più pagine di filtri diversi quando si cambia filtro durante il caricamento.
- I topic comparivano in ordine alfabetico inverso.

## [0.1.0] - 2026-11-07

### Aggiunto
- Struttura clean architecture feature-first (`lib/core`, `lib/features`).
- Stack: Riverpod, `go_router`, `supabase_flutter`, `equatable`, `json_serializable`, `very_good_analysis`.
- Bootstrap Supabase con configurazione da `--dart-define-from-file=.env` e schermata di configurazione mancante.
- Tema Material 3 chiaro e scuro, localizzazione in italiano.
- Autenticazione con email e password: registrazione (nome, cognome, username, email, password), login, logout, redirect del router in base alla sessione.
- CI GitHub Actions su ogni PR: `build_runner`, format, analyze, test.
- Schema di riferimento del database in `supabase/migrations/`.
