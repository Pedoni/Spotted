import 'dart:typed_data';

import 'package:spotted/features/channels/domain/channel_image_processor.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/features/channels/domain/repositories/channel_images_repository.dart';

/// Mette (o cambia) la foto o la copertina di un canale: prepara l'immagine
/// (proporzione, dimensioni e peso) e la carica.
class SetChannelImage {
  const SetChannelImage(this._repository, this._processor);

  final ChannelImagesRepository _repository;
  final ChannelImageProcessor _processor;

  /// Restituisce il nuovo percorso dell'immagine.
  Future<String> call({
    required String channelId,
    required ChannelImageKind kind,
    required Uint8List source,
  }) async {
    final bytes = await _processor.prepare(source, kind);
    return _repository.setImage(
      channelId: channelId,
      kind: kind,
      bytes: bytes,
    );
  }
}
