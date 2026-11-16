import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/features/channels/presentation/pages/channel_image_crop_page.dart';

/// Fa ritagliare una foto nella proporzione dell'immagine (quadrata per la
/// foto, 8:3 per la copertina). Un'interfaccia, così nei test si sostituisce
/// con una finta.
abstract interface class ChannelImageCropper {
  /// La parte ritagliata, o `null` se l'utente rinuncia.
  Future<Uint8List?> crop(
    BuildContext context,
    Uint8List source,
    ChannelImageKind kind,
  );
}

/// Apre la pagina di ritaglio a schermo intero.
class PageChannelImageCropper implements ChannelImageCropper {
  const PageChannelImageCropper();

  @override
  Future<Uint8List?> crop(
    BuildContext context,
    Uint8List source,
    ChannelImageKind kind,
  ) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChannelImageCropPage(source: source, kind: kind),
      ),
    );
  }
}
