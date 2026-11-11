# Changelog

Formato basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).
Versionamento `0.minor.patch` fino alla `1.0.0`.

## [0.6.0] - 2026-11-11

### Aggiunto
- Chat tra l'autore di uno spot e chi lo ha commentato: l'autore la avvia dal pulsante "Chatta" sui commenti degli altri. "Le mie chat" nel Profilo e pagina della chat con i messaggi (fino a 5000 caratteri); i nuovi messaggi arrivano controllando ogni pochi secondi mentre la chat è aperta.
- Rivelazione dell'identità: l'autore vede lo username del commentatore, mentre il commentatore vede l'autore come "Autore del post" finché l'autore non preme "Rivela identità" (con conferma, non si può annullare).

### Modificato
- Privacy: le tabelle `chats` e `messages` sono ridisegnate e chiuse ai client. Le funzioni del database non restituiscono mai gli id dei partecipanti, solo se l'utente è l'autore, se un messaggio è suo e, quando è consentito, lo username dell'altro. Chiude il debito di sicurezza su chat e messaggi.
- Il commentatore vede la chat solo dopo il primo messaggio dell'autore; sugli spot rimossi non si scrivono nuovi messaggi.
- Nuova funzione `is_spot_author`, che dice solo a chi chiama se è l'autore dello spot.

### Note
- Limite noto: nessuna segnalazione dei messaggi, blocco o uscita dalla chat; la moderazione delle chat arriva più avanti.

## [0.5.0] - 2026-11-11

### Aggiunto
- Strumenti del proprietario del canale: vede chi ha scritto uno spot (username), nasconde, ripristina o rimuove gli spot, nasconde e ripristina i commenti.
- Pagina "Moderazione" del canale (icona scudo, solo per il proprietario) con le schede "Segnalazioni" e "Spot nascosti".
- Segnalazione di spot e commenti con motivo (spam, offensivo, odio o discriminazione, altro) e dettagli facoltativi fino a 500 caratteri. Una sola segnalazione per contenuto, non si segnalano i propri contenuti.
- Il proprietario vede le segnalazioni aperte del suo canale e le chiude con "Risolvi" o "Ignora".
- Gli spot nascosti hanno l'etichetta "Nascosto dal proprietario del canale" in "I miei spot".

### Modificato
- Privacy: la tabella `reports` non è più accessibile ai client. Nessuno, nemmeno il proprietario, vede chi ha segnalato.
- Uno spot nascosto sparisce dal feed del canale; un commento nascosto lo vede solo il proprietario e il conteggio dei commenti lo ignora. Rimuovere uno spot è definitivo.
- `spot_detail`, `spot_comments` e `my_spots_page` restituiscono anche lo stato (`status`).
- Chiuso il debito di sicurezza sul vincolo anti-duplicati delle segnalazioni.

## [0.4.0] - 2026-11-11

### Aggiunto
- Pagina di dettaglio dello spot, aperta dal canale e da "I miei spot".
- Commenti agli spot: con lo username dell'autore, oppure "Autore del post" senza nome se commenta chi ha scritto lo spot. Testo fino a 500 caratteri, scorrimento infinito, cancellazione dei propri commenti dopo conferma.
- Like su spot e commenti, con conteggio; si aggiornano subito e tornano indietro se la richiesta fallisce.
- Gli spot mostrano il numero di commenti e di like.

### Modificato
- Privacy: le tabelle `comments`, `spot_likes` e `comment_likes` non sono più accessibili ai client. Nessuno vede chi mette like e `comments.author_id` non è leggibile (confrontato con l'autore dello spot lo rivelerebbe).
- Gli spot si leggono da funzioni del database (`channel_spots_page`, `spot_detail`, `my_spots_page`) che restituiscono anche i conteggi.
- I commenti non si modificano: si possono solo cancellare.

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
