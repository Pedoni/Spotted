# Changelog

Formato basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).
Versionamento `0.minor.patch` fino alla `1.0.0`.

## [0.10.0] - 2026-11-27

### Aggiunto
- **Approvazione degli spot e tag**: uno spot non esce subito. Chi lo scrive lo invia e il proprietario del canale lo pubblica scegliendo da 1 a 3 tag oppure lo rifiuta, dalla nuova scheda "Da approvare" della Moderazione (con il numero accanto al nome) o direttamente aprendo lo spot. Gli spot del proprietario si pubblicano subito, con i tag scelti nel modulo. L'autore vede lo spot in "I miei spot" con l'etichetta "In attesa di approvazione" o "Rifiutato"; gli spot già pubblicati restano pubblicati, senza tag. I tag sono un elenco fisso: 15 generici per tutti i canali e 62 in più per l'argomento Università. Le card mostrano i tag.
- **Chat tra utente e canale**: chiunque può scrivere a un canale dal pulsante "Scrivi al canale"; il proprietario risponde a nome del canale e resta anonimo, mentre vede lo username di chi scrive. Quando invii uno spot, in chat compare "Hai inviato uno spot", e poi "<canale> ha pubblicato il tuo spot" o "ha rifiutato il tuo spot". Toccando il messaggio si apre lo spot.
- **Messaggi non letti**: l'icona Chat nella barra in basso mostra quante chat hanno messaggi non letti (si ricontrolla ogni 30 secondi) e nell'elenco le chat non lette sono in grassetto con un puntino.
- **Limiti e blocco**: al massimo 5 messaggi senza risposta per chat con un canale e 5 spot in attesa per canale, con messaggi che dicono di aspettare. Il proprietario può bloccare un utente dalla chat (con conferma) e vedere e sbloccare i bloccati nella nuova scheda "Bloccati" della Moderazione. Un utente bloccato non può né scrivere al canale né inviargli spot, e riceve un messaggio generico che non dice chi l'ha bloccato.
- **Ricerca e filtro nella scheda Spots**: la barra di ricerca è sempre visibile in cima, al posto della lente, e un pulsante apre il filtro per tag (con il numero di tag scelti, chip che si tolgono con la "x" e "Azzera"). Con più tag restano gli spot che ne hanno almeno uno; il filtro si somma al testo cercato.
- **Mappa dei canali**: in Canali → Esplora un interruttore Lista / Mappa. Un pin per ogni comune che ha canali (la foto del canale se è uno solo, il numero se sono di più; un tocco apre il canale o l'elenco di quel comune), con gli stessi filtri della lista. Mappa di OpenStreetMap con l'attribuzione sempre visibile.
- **Profilo**: "Cambia password" e "Cambia email" (chiedono la password attuale; la nuova email resta in attesa di conferma e il Profilo la mostra, mentre quella di adesso resta valida) e "Modifica i miei dati" (nome, cognome e data di nascita facoltativa; lo username non si cambia).

### Modificato
- **La città è obbligatoria** per i canali nuovi e per quelli modificati (anche un canale solo online indica una città, per esempio la sede). I canali nati senza città restano come sono: il proprietario vede un invito ad aggiungerla.
- La pubblicazione di uno spot da parte di un utente non è più immediata: vedi "Approvazione degli spot".
- Le schede della Moderazione scorrono di lato (sono quattro).

### Corretto
- Dopo ogni modifica dei dati dell'utente (come il cambio di email) l'app tornava alla Home invece che alla schermata da cui si era partiti: ora il percorso si rifà solo quando si entra o si esce.
- Android: il permesso INTERNET mancava nelle versioni di rilascio (c'era solo in debug e profile), quindi un'app di rilascio non avrebbe raggiunto né Supabase né le mappe.

### Database
Migrazioni da applicare **in ordine** (quelle già applicate in prova si saltano). L'app nuova non funziona senza; quella vecchia continua a funzionare tranne dove indicato:
- `20261126100000`: stati `pending` e `rejected` degli spot (**da qui in poi uno spot nuovo nasce in attesa**), tabella `tags` con i dati, `spots.tags` e le funzioni di approvazione.
- `20261127100000`: chat tra utente e canale (`channel_chats`, `channel_chat_messages`, `start_channel_chat`) e messaggi di sistema scritti dal database.
- `20261128100000`: messaggi non letti (`mark_chat_read`, `unread_chats_count`, `unread` nelle chat).
- `20261129100000`: limiti e blocco (`channel_blocks`, trigger sugli spot, `send_message` con i limiti).
- `20261130100000`: filtro per tag in `channel_spots_page` (cambia la firma: la versione vecchia viene eliminata).
- `20261201100000`: città obbligatoria (**un canale non si crea più senza comune**).
- `20261202100000`..`20261202100400`: coordinate dei comuni, in quattro parti; l'ultima controlla che nessun comune resti senza coordinate.
- `20261203100000`: `channels_map`, per la mappa.
- `20261204100000`: `update_my_profile` e chiusura dell'`update` diretto su `profiles`.

### Sicurezza
- **Chiuso un buco della baseline**: ogni utente poteva fare un `update` diretto sulla propria riga di `profiles`, quindi anche cambiare lo username senza controlli. Ora nome, cognome e data di nascita si cambiano solo con `update_my_profile`.
- Chat con i canali, blocchi e messaggi di sistema hanno le tabelle chiuse ai client: nessuna funzione restituisce id di utenti. Chi scrive non può scoprire di essere stato bloccato, e il proprietario del canale non compare mai.
- Il controllo della password attuale per cambiare password o email avviene riaccedendo con l'email dell'utente.

### Da sapere
- **Coordinate dei comuni**: la fonte (`coordinate.csv` di Open Data Sicilia) non ha una licenza esplicita: da verificare prima di aprire a utenti reali. Sono state corrette 11 righe senza punto decimale, 6 comuni nati da fusioni e Sassofeltrio.
- **Riquadri della mappa**: i server pubblici di OpenStreetMap vanno bene per sviluppo e prove, non per un uso intenso: prima del lancio serve un fornitore adatto.
- **Cambio email**: dipende dalle impostazioni di Supabase Auth ("Secure email change", modelli email in italiano, indirizzo a cui porta il link di conferma).
- Foto del profilo, notifiche, eliminazione dell'account e pagine di privacy e condizioni d'uso arrivano dopo.

## [0.9.0] - 2026-11-17

### Aggiunto
- News dei canali: comunicazioni del canale, scritte solo dal proprietario e lette da tutti (titolo e testo). Si vedono nella scheda News della pagina del canale, in una pagina di dettaglio, e il proprietario può pubblicarle, modificarle ed eliminarle (con conferma). Nessun autore mostrato: parla il canale.
- Eventi dei canali: titolo, descrizione, luogo facoltativo (testo libero, per esempio "Aula magna"), inizio e fine facoltativa, scelti con i selettori di data e ora. La scheda Eventi ha "Prossimi" e "Passati"; un evento senza fine resta tra i prossimi per tre ore dopo l'inizio. Solo il proprietario li crea, li modifica e li elimina; creando, l'inizio deve essere nel futuro.
- Home: i caroselli "Prossimi eventi" e "Ultime news" dei canali che segui, con la freccia (e la sesta card "Visualizza tutti") verso l'elenco completo. Le sezioni ci sono sempre: senza contenuti dicono che non c'è niente.
- Foto e copertina dei canali personalizzabili dal proprietario: una matita sulla foto e sulla copertina apre le scelte galleria, fotocamera e rimuovi; l'immagine si ritaglia nella proporzione giusta (quadrata la foto, 8:3 la copertina), si ridimensiona, si comprime e perde i dati nascosti come la posizione.
- Informazioni sull'app nel Profilo: logo, versione e numero di build, e le licenze open source (anche quelle dei font dell'app). Nel Profilo ci sono anche le voci "Modifica i miei dati", "Cambia email", "Notifiche", "Privacy" e "Condizioni d'uso", per ora spente e con scritto "In arrivo".
- Modelli di issue e di pull request per il repository.

### Modificato
- Home: non c'è più il pulsante "Pubblica": gli spot si pubblicano dalla pagina del canale. Il carosello "I miei spot" resta, e i tre caroselli condividono lo stesso aspetto.
- Il segnaposto della scheda Spots ha ora un sottotitolo ("Scrivi il primo!"), come Eventi e News.
- Eliminando un canale spariscono anche le sue news e i suoi eventi; il testo di conferma lo dice.

### Corretto
- Uscendo dall'account dal Profilo poteva comparire un errore ("Using ref when a widget is about to or has been unmounted"): ora l'uscita funziona senza errori. Stessa precauzione nella cancellazione di un commento.

### Database
Migrazioni da applicare **prima** di distribuire l'app, in ordine:
- `20261121100000`: foto e copertina dei canali (colonne, bucket `channel-images` pubblico con tetto di 1 MB e regole sui file).
- `20261122100000`: `channel_news` e le sue funzioni (`channel_news_page`, `news_detail`, `create_`, `update_` e `delete_channel_news`).
- `20261123100000`: `followed_news_page`, le news dei canali seguiti.
- `20261124100000`: `channel_events` e le sue funzioni (`channel_events_page`, `event_detail`, `create_`, `update_` e `delete_channel_event`).
- `20261125100000`: `followed_events_page`, i prossimi eventi dei canali seguiti.

### Sicurezza
- Lo storage registra chi carica ogni file: per non rivelare il proprietario di un canale, le regole sul bucket delle immagini (inserire, leggere e cancellare) sono tutte limitate al proprietario del canale. Gli altri vedono le immagini perché il bucket è pubblico, ma non possono elencarle né cancellarle.
- News ed eventi hanno la tabella chiusa ai client e nessuna colonna con l'autore; le funzioni non restituiscono mai id di utenti.
- Verificato con un test che dopo l'uscita non resti niente delle news e degli eventi dell'utente precedente.

### Note
- Cambio password, cambio email, modifica dei dati, foto del profilo, notifiche, eliminazione dell'account e pagine di privacy e condizioni d'uso arrivano dopo.
- Il feed degli spot dei canali seguiti è ancora pronto ma non mostrato: si deciderà cosa aggiungere sotto i caroselli.

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
