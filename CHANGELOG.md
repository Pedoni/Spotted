# Changelog

Formato basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).
Versionamento `0.minor.patch` fino alla `1.0.0`.

## [0.8.0] - 2026-11-15

### Aggiunto
- Luogo dei canali da un elenco ufficiale: il comune si sceglie tra i 7.896 dell'ISTAT con suggerimenti mentre si scrive (senza distinguere maiuscole e accenti), è facoltativo e si mostra sempre con la sigla, per esempio "Pisa (PI)". Il database rifiuta un comune che non esiste.
- Ricerca di testo negli spot di un canale (dalla lente nella pagina del canale): cerca nel titolo e nel testo, ovunque e senza distinguere maiuscole e accenti, parte da due lettere ed evidenzia in giallo ciò che trova.
- Filtri dei canali in un foglio dal basso (pulsante con il numero di filtri attivi accanto alla ricerca): argomento, regione, provincia e comune, tenuti coerenti tra loro, con "Azzera".
- Modifica ed eliminazione del canale per il proprietario, da un menu nella pagina del canale: si cambiano nome, argomento, comune e descrizione (l'indirizzo non cambia mai); l'eliminazione chiede conferma e porta via anche spot, commenti e chat del canale.
- Pagina del canale con copertina (per ora la stessa di marca per tutti), foto quadrata del canale e, sotto gli iscritti, le schede Spots, Eventi e News (Eventi e News per ora dicono solo che non c'è niente). Copertina e foto sono già pronte ad accettare immagini vere.
- Controllo dello username mentre si scrive nella registrazione: "disponibile" o "già in uso", che blocca l'invio.
- Scelta del tema nel Profilo: chiaro (predefinito), scuro o come il telefono, ricordata tra un avvio e l'altro. "Cambia password" ed "Elimina profilo" ci sono ma per ora non fanno nulla.
- Stati vuoti con icona, testo che dice cosa fare e, dove serve, un pulsante (per esempio "Crea il tuo primo canale" o "Azzera" i filtri).

### Modificato
- Nuova navigazione: quattro schede in basso (Home, Canali, Chat, Profilo). Canali ha tre schede in alto, scorrevoli di lato: Esplora (tutti, con ricerca e filtri), Seguiti e Miei (creati da te). Le chat hanno la loro scheda.
- Home: mostra "I miei spot" in un carosello con gli ultimi cinque (la sesta card e la freccia portano all'elenco completo) e il pulsante "Pubblica", che chiede in quale canale seguito scrivere. I canali seguiti sono in Canali > Seguiti.
- Profilo: foto segnaposto e nome in alto, poi tema, account ed uscita; non c'è più una pagina Impostazioni separata.
- Orari mostrati sempre con l'ora oltre alla data ("31 dic 2025 · 14:30"), in ora locale.
- Prima di uscire dall'account compare una conferma; se l'uscita non riesce si vede l'errore e si resta dentro.
- Tutte le icone sono nella versione arrotondata.

### Database
Migrazioni da applicare, in ordine:
- `20261116100000` e `20261116100100`-`400`: comuni e collegamento con i canali (già applicate).
- `20261117100000`: i client scrivono un canale solo dalle colonne consentite; **da applicare dopo l'aggiornamento dell'app**.
- `20261118100000`: ricerca di testo negli spot (cambia la firma di `channel_spots_page`).
- `20261119100000`: `followed_spots_page`, gli spot dei canali seguiti (pronta, l'app per ora non la mostra).
- `20261120100000`: `update_channel` e `delete_channel` per il proprietario.

### Sicurezza
- Verificato con un test che dopo l'uscita non resti niente dell'utente precedente (dati, "mi piace", ricerche, scheda aperta, profilo).
- Chiuso il debito su `handle_new_user`: lo username è validato prima della registrazione (formato e disponibilità).

### Note
- Il feed degli spot dei canali seguiti è pronto ma non è mostrato: si deciderà cosa aggiungere sotto "I miei spot".
- Foto e copertina del canale non sono ancora personalizzabili: servono colonne e archiviazione.
- Cambio password, eliminazione del profilo e immagine del profilo personalizzata arrivano dopo.

## [0.7.0] - 2026-11-11

### Aggiunto
- Nuovo aspetto dell'app, tema chiaro e scuro: palette "Crush" con tre colori (lampone per l'azione principale e i "mi piace", indaco per l'anonimato, giallo come evidenziatore) su crema o inchiostro viola, forme morbide (card e finestre arrotondate, bottoni e barra di navigazione a pillola, card degli spot e bolle dei messaggi "a fumetto") e font inclusi nell'app: Bricolage Grotesque per i titoli e Plus Jakarta Sans per il testo.
- Caricamenti con scheletri: ogni lista e pagina mostra la forma della schermata vera con uno shimmer morbido al posto dello spinner; in fondo agli elenchi compare un elemento scheletro mentre arriva la pagina successiva.
- Nuova icona (un radar con tre puntini nei colori della palette), con icona adattiva e icona a tema su Android, e splash scura con il logo e la scritta "Spotted".
- Accesso e registrazione con il marchio in alto (macchie colorate, radar e scritta) e un foglio con il modulo; il radar ruota una volta all'apertura e sta fermo se il sistema riduce le animazioni. Gli errori dei moduli compaiono in un riquadro con icona.
- Avatar dei canali a quadrato morbido con l'iniziale e un colore della palette sempre uguale per lo stesso canale; nell'elenco delle chat l'autore anonimo è una maschera su indaco.
- Il cuore dei "mi piace" è lampone e rimbalza quando viene messo.

### Modificato
- Le bolle dei messaggi seguono la lunghezza del testo (prima erano sempre larghe l'80% dello schermo) e hanno la coda dalla parte di chi scrive.
- "Autore del post" nei commenti è in indaco, il colore dell'anonimato.
- Tutti i campi di testo usano lo stesso bordo morbido del tema (tolti i bordi scritti a mano in 15 punti).
- Il nome dell'app su Android è "Spotted" (era "spotted").
- Il progetto di sviluppo usa Flutter 3.47.9, anche nella pipeline.

### Note
- La scelta manuale tra tema chiaro e scuro arriva con le impostazioni (0.8.0): per ora il tema segue il sistema.
- Le icone dell'interfaccia sono ancora quelle standard di Material, in attesa delle versioni arrotondate.

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
