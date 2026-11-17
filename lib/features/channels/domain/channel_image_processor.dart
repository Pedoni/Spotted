import 'dart:typed_data';

import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';

/// Prepara una foto da caricare: la porta nella proporzione giusta, la
/// ridimensiona, la comprime e toglie i dati nascosti (posizione, modello del
/// telefono, data).
abstract interface class ChannelImageProcessor {
  /// Restituisce un JPEG pronto da caricare. Lancia `ImageFailure` se [source]
  /// non è un'immagine o è troppo grande per essere aperta.
  Future<Uint8List> prepare(Uint8List source, ChannelImageKind kind);
}
