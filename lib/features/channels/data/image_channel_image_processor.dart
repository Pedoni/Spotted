import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/channel_image_processor.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';

/// Prepara le immagini con il pacchetto `image`, in un isolate (non blocca
/// l'interfaccia): le porta nella proporzione giusta, le ridimensiona, le
/// comprime in JPEG sotto il peso massimo e toglie i dati nascosti.
class ImageChannelImageProcessor implements ChannelImageProcessor {
  const ImageChannelImageProcessor();

  /// Le qualità provate, dalla migliore: la prima sotto il peso massimo.
  static const _qualities = [85, 78, 70, 62, 55, 48, 40];

  /// Se nemmeno la qualità più bassa basta, si riduce la larghezza di questo
  /// fattore e si riprova, al massimo [_maxShrinks] volte.
  static const _shrinkFactor = 0.85;
  static const _maxShrinks = 4;

  @override
  Future<Uint8List> prepare(Uint8List source, ChannelImageKind kind) async {
    if (source.length > ChannelImageKind.maxSourceBytes) {
      throw const ImageFailure(ImageFailureReason.tooLarge);
    }
    final result = await Isolate.run(() => process(source, kind));
    if (result == null) throw const ImageFailure(ImageFailureReason.invalid);
    return result;
  }

  /// Il lavoro vero. `null` se [source] non è un'immagine. Pubblico per
  /// poterlo provare senza isolate.
  static Uint8List? process(Uint8List source, ChannelImageKind kind) {
    final decoded = img.decodeImage(source);
    if (decoded == null) return null;

    // Le foto del telefono sono salvate di lato con un'etichetta che dice come
    // girarle: la si applica, poi i dati nascosti si buttano.
    final upright = img.bakeOrientation(decoded);
    final cropped = _cropToRatio(upright, kind.aspectRatio);

    var width = min(kind.maxWidth, cropped.width);
    Uint8List? smallest;
    for (var shrink = 0; shrink <= _maxShrinks; shrink++) {
      final resized = img.copyResize(
        cropped,
        width: width,
        height: kind.heightFor(width),
        interpolation: img.Interpolation.average,
      )..exif = img.ExifData();
      for (final quality in _qualities) {
        final bytes = img.encodeJpg(resized, quality: quality);
        if (smallest == null || bytes.length < smallest.length) {
          smallest = bytes;
        }
        if (bytes.length <= kind.maxBytes) return bytes;
      }
      width = (width * _shrinkFactor).round();
    }
    return smallest;
  }

  /// Toglie il di più (al centro) perché l'immagine abbia la [ratio] voluta.
  static img.Image _cropToRatio(img.Image image, double ratio) {
    final current = image.width / image.height;
    if ((current - ratio).abs() < 0.005) return image;
    if (current > ratio) {
      final width = (image.height * ratio).round();
      return img.copyCrop(
        image,
        x: (image.width - width) ~/ 2,
        y: 0,
        width: width,
        height: image.height,
      );
    }
    final height = (image.width / ratio).round();
    return img.copyCrop(
      image,
      x: 0,
      y: (image.height - height) ~/ 2,
      width: image.width,
      height: height,
    );
  }
}
