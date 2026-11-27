/// Cosa fa l'admin su una segnalazione.
enum AdminAction {
  /// Segnalazione infondata: si chiude come ignorata.
  dismiss,

  /// Già sistemata: si chiude come risolta, senza toccare il contenuto.
  resolve,

  /// Nasconde lo spot o il commento e chiude le segnalazioni su di esso. Il
  /// proprietario del canale può ripristinarlo.
  hide,

  /// Rimuove lo spot (definitivo) e chiude le segnalazioni su di esso. Non vale
  /// per i commenti.
  remove,
}
