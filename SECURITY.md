# Sicurezza

## Segnalare una vulnerabilità

Se trovi un problema di sicurezza (per esempio un modo di vedere chi ha scritto
uno spot anonimo, di leggere dati di altri utenti o di scrivere dove non si
dovrebbe), **non aprire una issue pubblica**.

Usa la segnalazione privata di GitHub: scheda **Security** del repository →
**Report a vulnerability**. Ti rispondiamo il prima possibile e, quando il
problema è risolto, ti citiamo se vuoi.

Aiuta se scrivi cosa hai fatto passo per passo, cosa ti aspettavi e cosa è
successo.

## Cosa è protetto

Spotted è un'app con spot **anonimi**: solo il proprietario di un canale vede
l'autore di uno spot, e il proprietario di un canale non è mai mostrato. I dati
stanno su Supabase e la sicurezza si basa su RLS, permessi per colonna e
funzioni riservate, non sul nascondere la chiave `anon` (che finisce nell'app).
Le regole sono descritte nella sezione "Database" di `CLAUDE.md`.

## Segreti

Nel repository non devono finire chiavi: l'URL e la chiave `anon` di Supabase
stanno in `.env` (ignorato da git, il modello è `.env.example`) e la chiave
`service_role` non si usa mai nell'app. Il repository ha attivi la
scansione dei segreti e il blocco dei push che li contengono.
