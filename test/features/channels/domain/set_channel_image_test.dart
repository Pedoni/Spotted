import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/features/channels/domain/usecases/remove_channel_image.dart';
import 'package:spotted/features/channels/domain/usecases/set_channel_image.dart';

import '../../../helpers/fake_channel_images.dart';

void main() {
  final source = Uint8List.fromList([1, 2, 3]);

  late FakeChannelImagesRepository repository;
  late FakeChannelImageProcessor processor;

  setUp(() {
    repository = FakeChannelImagesRepository();
    processor = FakeChannelImageProcessor();
  });

  group('SetChannelImage', () {
    test('prepara la foto e poi la carica', () async {
      final path = await SetChannelImage(repository, processor)(
        channelId: 'c1',
        kind: ChannelImageKind.cover,
        source: source,
      );

      expect(processor.calls.single.kind, ChannelImageKind.cover);
      expect(processor.calls.single.source, source);
      expect(repository.setCalls.single.channelId, 'c1');
      expect(repository.setCalls.single.kind, ChannelImageKind.cover);
      expect(path, 'c1/cover-1.jpg');
    });

    test('carica quello che ha preparato il processore', () async {
      final prepared = Uint8List.fromList([9, 9]);
      final custom = _FixedProcessor(prepared);

      await SetChannelImage(repository, custom)(
        channelId: 'c1',
        kind: ChannelImageKind.avatar,
        source: source,
      );

      expect(repository.setCalls.single.bytes, prepared);
    });

    test('se la foto non si può usare non carica niente', () async {
      processor.error = const ImageFailure(ImageFailureReason.invalid);

      await expectLater(
        SetChannelImage(repository, processor)(
          channelId: 'c1',
          kind: ChannelImageKind.avatar,
          source: source,
        ),
        throwsA(const ImageFailure(ImageFailureReason.invalid)),
      );
      expect(repository.setCalls, isEmpty);
    });

    test("l'errore del caricamento passa così com'è", () async {
      repository.setError = const NetworkFailure();

      await expectLater(
        SetChannelImage(repository, processor)(
          channelId: 'c1',
          kind: ChannelImageKind.avatar,
          source: source,
        ),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('RemoveChannelImage', () {
    test("chiede di togliere l'immagine giusta", () async {
      await RemoveChannelImage(repository)(
        channelId: 'c1',
        kind: ChannelImageKind.avatar,
      );

      expect(repository.removeCalls.single.channelId, 'c1');
      expect(repository.removeCalls.single.kind, ChannelImageKind.avatar);
    });

    test("l'errore passa così com'è", () async {
      repository.removeError = const PermissionFailure();

      await expectLater(
        RemoveChannelImage(repository)(
          channelId: 'c1',
          kind: ChannelImageKind.cover,
        ),
        throwsA(isA<PermissionFailure>()),
      );
    });
  });
}

class _FixedProcessor extends FakeChannelImageProcessor {
  _FixedProcessor(this.output);

  final Uint8List output;

  @override
  Future<Uint8List> prepare(Uint8List source, ChannelImageKind kind) async =>
      output;
}
