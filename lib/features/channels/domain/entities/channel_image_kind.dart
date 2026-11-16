/// Le due immagini di un canale e come devono essere fatte.
enum ChannelImageKind {
  /// La foto del canale: quadrata.
  avatar(
    aspectRatio: 1,
    maxWidth: 512,
    maxBytes: 150 * 1024,
  ),

  /// La copertina: larga, in proporzione 8:3 (come sta sullo schermo di un
  /// telefono, così si vede quasi tutta).
  cover(
    aspectRatio: 8 / 3,
    maxWidth: 1280,
    maxBytes: 300 * 1024,
  );

  const ChannelImageKind({
    required this.aspectRatio,
    required this.maxWidth,
    required this.maxBytes,
  });

  /// Larghezza diviso altezza dell'immagine salvata.
  final double aspectRatio;

  /// La larghezza massima in pixel: più grande non serve e pesa.
  final int maxWidth;

  /// Il peso massimo dopo la compressione.
  final int maxBytes;

  /// L'altezza che corrisponde a [width], nella proporzione giusta.
  int heightFor(int width) => (width / aspectRatio).round();

  /// Il peso massimo di una foto scelta dall'utente, prima di ridurla. Oltre,
  /// non la si apre nemmeno.
  static const int maxSourceBytes = 15 * 1024 * 1024;
}
