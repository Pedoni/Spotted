import 'package:flutter/material.dart';

/// Raggi degli angoli: forme morbide e giocose.
abstract final class AppRadius {
  /// Elementi piccoli (menu, riquadri interni).
  static const sm = 12.0;

  /// Campi di testo, snackbar.
  static const md = 20.0;

  /// Card, finestre di dialogo, fogli in basso.
  static const lg = 28.0;

  /// L'angolo "a fumetto": quasi dritto, sulle card degli spot e sulle bolle
  /// dei messaggi.
  static const bubbleCorner = 8.0;
}

abstract final class AppShapes {
  /// Card normale: angoli uguali.
  static RoundedRectangleBorder card({BorderSide side = BorderSide.none}) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: side,
    );
  }

  /// Fumetto: tutti gli angoli arrotondati tranne quello in basso a sinistra.
  static const bubbleRadius = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.lg),
    topRight: Radius.circular(AppRadius.lg),
    bottomRight: Radius.circular(AppRadius.lg),
    bottomLeft: Radius.circular(AppRadius.bubbleCorner),
  );

  /// Fumetto di un messaggio dell'altro: la "coda" è in basso a sinistra.
  static BorderRadius messageRadius({required bool mine}) {
    const big = Radius.circular(20);
    const small = Radius.circular(AppRadius.bubbleCorner);
    return mine
        ? const BorderRadius.only(
            topLeft: big,
            topRight: big,
            bottomLeft: big,
            bottomRight: small,
          )
        : const BorderRadius.only(
            topLeft: big,
            topRight: big,
            bottomLeft: small,
            bottomRight: big,
          );
  }
}
