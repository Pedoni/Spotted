-- Coordinate dei comuni (per la mappa dei canali, #57).
--
-- Aggiunge `latitude` e `longitude` a `municipalities` (WGS84, 5 decimali,
-- circa un metro). Si caricano con le migrazioni `20261202100100`..
-- `20261202100400`, nello stesso ordine e con gli stessi gruppi di quelle dei
-- comuni (`20261116100100`..`20261116100400`).
--
-- Fonte: `coordinate.csv` del progetto Open Data Sicilia
-- (https://github.com/opendatasicilia/comuni-italiani, cartella `dati`): il
-- centro del comune, riferito al municipio, in `EPSG:4326`. Il file non porta
-- una licenza esplicita (i dati di base vengono da Agid-iPA, aperti): da
-- verificare prima di aprire a utenti reali.
--
-- Correzioni fatte al file prima di caricarlo (verificate: 7.896 comuni, tutti
-- dentro l'Italia, nessuno a più di 90 km dalla mediana della sua provincia,
-- tranne le isole lontane):
--   * 11 righe avevano perso il punto decimale (per esempio `8339.0` invece di
--     `8.339`): si è diviso per 1000;
--   * 6 comuni nati da fusioni (Moransengo-Tonengo, Bardello con Malgesso e
--     Bregano, Uggiate con Ronago, Sovizzo, Setteville, Santa Caterina
--     d'Este) non c'erano: si è usata la media dei comuni da cui nascono;
--   * Sassofeltrio non c'era: coordinate prese da Wikipedia
--     (https://en.wikipedia.org/wiki/Sassofeltrio), circa 43.883, 12.517.
-- Quando i comuni cambiano (fusioni) la migrazione che li aggiorna aggiorna
-- anche le coordinate.
--
-- Le coordinate sono pubbliche come il resto dell'elenco: nessun dato
-- dell'utente.

alter table public.municipalities
  add column latitude numeric(8, 5) null,
  add column longitude numeric(8, 5) null,
  add constraint municipalities_latitude_check
    check (latitude between -90 and 90),
  add constraint municipalities_longitude_check
    check (longitude between -180 and 180),
  add constraint municipalities_coordinates_check
    check ((latitude is null) = (longitude is null));
