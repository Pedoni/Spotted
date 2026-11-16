import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';

/// Da dove si prende la foto.
enum ChannelImageSource { gallery, camera }

/// Fa scegliere (o scattare) una foto. Un'interfaccia, così nei test si
/// sostituisce con una finta.
abstract interface class ChannelImagePicker {
  /// I byte della foto scelta, o `null` se l'utente rinuncia. Lancia
  /// `ImageFailure` se pesa troppo e un'eccezione della piattaforma se la
  /// galleria o la fotocamera non si aprono.
  Future<Uint8List?> pick(ChannelImageSource source);
}

/// Usa la galleria e la fotocamera del telefono.
class DeviceChannelImagePicker implements ChannelImagePicker {
  DeviceChannelImagePicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  /// Il lato più lungo di una foto appena scelta: il telefono la riduce subito
  /// (le foto di oggi sono enormi e riempirebbero la memoria per niente).
  static const maxSide = 2048.0;

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(ChannelImageSource source) async {
    final file = await _picker.pickImage(
      source: switch (source) {
        ChannelImageSource.gallery => ImageSource.gallery,
        ChannelImageSource.camera => ImageSource.camera,
      },
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: 90,
    );
    if (file == null) return null;
    if (await file.length() > ChannelImageKind.maxSourceBytes) {
      throw const ImageFailure(ImageFailureReason.tooLarge);
    }
    return file.readAsBytes();
  }
}
