import 'dart:typed_data';

import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';

/// Contratto delle immagini di un canale. Le implementazioni lanciano un
/// `Failure`.
abstract interface class ChannelImagesRepository {
  /// Carica [bytes] (un JPEG già ridotto), lo collega al canale e toglie il
  /// file che c'era prima. Restituisce il nuovo percorso. Se qualcosa va storto
  /// il canale resta com'era.
  Future<String> setImage({
    required String channelId,
    required ChannelImageKind kind,
    required Uint8List bytes,
  });

  /// Toglie l'immagine dal canale e cancella il file.
  Future<void> removeImage({
    required String channelId,
    required ChannelImageKind kind,
  });

  /// Cancella dei file dallo storage (quando si elimina un canale). Non lancia
  /// se un file non c'è.
  Future<void> deleteFiles(List<String> paths);
}
