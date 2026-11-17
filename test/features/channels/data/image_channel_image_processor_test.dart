import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/data/image_channel_image_processor.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';

/// Un'immagine di [width]x[height] con colori a caso, quindi difficile da
/// comprimere come una foto vera.
img.Image noisyImage(int width, int height, {int seed = 1}) {
  final random = Random(seed);
  final image = img.Image(width: width, height: height);
  for (final pixel in image) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
  }
  return image;
}

Uint8List png(img.Image image) => img.encodePng(image);

img.Image decode(Uint8List bytes) => img.decodeJpg(bytes)!;

void main() {
  const processor = ImageChannelImageProcessor();

  group('proporzione', () {
    test('la foto è quadrata anche partendo da un orizzontale', () async {
      final out = await processor.prepare(
        png(noisyImage(1200, 800)),
        ChannelImageKind.avatar,
      );

      final result = decode(out);
      expect(result.width, result.height);
    });

    test('la foto è quadrata anche partendo da un verticale', () async {
      final out = await processor.prepare(
        png(noisyImage(500, 900)),
        ChannelImageKind.avatar,
      );

      final result = decode(out);
      expect(result.width, result.height);
    });

    test('la copertina è 8:3 anche partendo da una foto verticale', () async {
      final out = await processor.prepare(
        png(noisyImage(600, 900)),
        ChannelImageKind.cover,
      );

      final result = decode(out);
      expect(result.width / result.height, closeTo(8 / 3, 0.02));
    });

    test('una foto già nella proporzione giusta non viene tagliata', () async {
      final out = await processor.prepare(
        png(noisyImage(400, 400)),
        ChannelImageKind.avatar,
      );

      expect(decode(out).width, 400);
    });
  });

  group('dimensioni', () {
    test('la foto non supera la larghezza massima', () async {
      final out = await processor.prepare(
        png(noisyImage(2000, 2000)),
        ChannelImageKind.avatar,
      );

      expect(
        decode(out).width,
        lessThanOrEqualTo(ChannelImageKind.avatar.maxWidth),
      );
    });

    test('la copertina non supera la larghezza massima', () async {
      final out = await processor.prepare(
        png(noisyImage(2400, 900)),
        ChannelImageKind.cover,
      );

      expect(
        decode(out).width,
        lessThanOrEqualTo(ChannelImageKind.cover.maxWidth),
      );
    });

    test('una foto piccola non viene ingrandita', () async {
      final out = await processor.prepare(
        png(noisyImage(100, 100)),
        ChannelImageKind.avatar,
      );

      expect(decode(out).width, 100);
    });
  });

  group('peso', () {
    test('la foto sta sotto il peso massimo', () async {
      final out = await processor.prepare(
        png(noisyImage(1500, 1500)),
        ChannelImageKind.avatar,
      );

      expect(out.length, lessThanOrEqualTo(ChannelImageKind.avatar.maxBytes));
    });

    test('la copertina sta sotto il peso massimo', () async {
      final out = await processor.prepare(
        png(noisyImage(2400, 900)),
        ChannelImageKind.cover,
      );

      expect(out.length, lessThanOrEqualTo(ChannelImageKind.cover.maxBytes));
    });

    test('il risultato è un JPEG', () async {
      final out = await processor.prepare(
        png(noisyImage(300, 300)),
        ChannelImageKind.avatar,
      );

      // I JPEG iniziano con FF D8.
      expect(out.sublist(0, 2), [0xFF, 0xD8]);
    });
  });

  group('dati nascosti', () {
    test('la posizione e gli altri dati della foto non restano', () async {
      final source = noisyImage(400, 400)
        ..exif.imageIfd['Make'] = 'Telefono Segreto'
        ..exif.gpsIfd.gpsLatitude = 43.7;
      final jpeg = img.encodeJpg(source);
      expect(img.decodeJpg(jpeg)!.hasExif, isTrue);

      final out = await processor.prepare(jpeg, ChannelImageKind.avatar);

      final result = decode(out);
      expect(result.exif.isEmpty, isTrue);
    });

    test('una foto girata di lato (dati nascosti) viene raddrizzata', () async {
      // 600x300 con "ruota di 90 gradi": in realtà è alta 300x600.
      final source = noisyImage(600, 300)..exif.imageIfd.orientation = 6;
      final jpeg = img.encodeJpg(source);

      final out = await processor.prepare(jpeg, ChannelImageKind.cover);

      // Raddrizzata è 300x600, poi tagliata in 8:3: larga 300.
      expect(decode(out).width, 300);
    });
  });

  group('file non validi', () {
    test('un file che non è un immagine: ImageFailure invalid', () async {
      await expectLater(
        processor.prepare(
          Uint8List.fromList(List.filled(200, 7)),
          ChannelImageKind.avatar,
        ),
        throwsA(const ImageFailure(ImageFailureReason.invalid)),
      );
    });

    test('un file vuoto: ImageFailure invalid', () async {
      await expectLater(
        processor.prepare(Uint8List(0), ChannelImageKind.cover),
        throwsA(const ImageFailure(ImageFailureReason.invalid)),
      );
    });

    test('un file troppo pesante non si apre: ImageFailure tooLarge', () async {
      final huge = Uint8List(ChannelImageKind.maxSourceBytes + 1);

      await expectLater(
        processor.prepare(huge, ChannelImageKind.avatar),
        throwsA(const ImageFailure(ImageFailureReason.tooLarge)),
      );
    });
  });

  group('ChannelImageKind', () {
    test('la foto è quadrata e la copertina è 8:3', () {
      expect(ChannelImageKind.avatar.aspectRatio, 1);
      expect(ChannelImageKind.cover.aspectRatio, closeTo(2.667, 0.001));
    });

    test("l'altezza segue la proporzione", () {
      expect(ChannelImageKind.avatar.heightFor(512), 512);
      expect(ChannelImageKind.cover.heightFor(1280), 480);
    });

    test('i pesi massimi sono piccoli', () {
      expect(ChannelImageKind.avatar.maxBytes, lessThanOrEqualTo(200 * 1024));
      expect(ChannelImageKind.cover.maxBytes, lessThanOrEqualTo(400 * 1024));
    });
  });
}
