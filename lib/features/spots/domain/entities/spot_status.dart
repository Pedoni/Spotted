/// Stato di uno spot visibile ai client. Gli spot rimossi non arrivano mai.
///
/// `pending` e `rejected` li vedono solo l'autore e il proprietario del
/// canale: uno spot nuovo aspetta l'approvazione del proprietario.
enum SpotStatus { published, hidden, pending, rejected }
