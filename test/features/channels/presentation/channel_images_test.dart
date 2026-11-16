import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/features/channels/presentation/services/channel_image_picker.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_cover.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_header.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_image_edit_button.dart';

import '../../../helpers/fake_channel_images.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final picked = Uint8List.fromList([1, 2, 3]);
  final cropped = Uint8List.fromList([4, 5, 6]);

  late FakeChannelsRepository channels;
  late FakeChannelImagesRepository images;
  late FakeChannelImagePicker picker;
  late FakeChannelImageCropper cropper;

  String? urlOf(String? path) => path == null ? null : 'https://img.test/$path';

  /// Le immagini di rete che compaiono con questo indirizzo.
  Finder networkImage(String url) => find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.image is NetworkImage &&
        (widget.image as NetworkImage).url == url,
  );

  /// Apre Canali → il canale "Spotted Pisa".
  Future<void> openChannel(
    WidgetTester tester, {
    bool owner = true,
    String? avatarPath,
    String? coverPath,
  }) async {
    final channel = makeChannel(
      1,
      name: 'Spotted Pisa',
      avatarPath: avatarPath,
      coverPath: coverPath,
    );
    channels = FakeChannelsRepository(channels: [channel], mine: [channel]);
    images = FakeChannelImagesRepository(channels);
    picker = FakeChannelImagePicker(bytes: picked);
    cropper = FakeChannelImageCropper(result: cropped);
    await pumpApp(
      tester,
      channels: channels,
      moderation: FakeModerationRepository(
        ownedChannelIds: owner ? {'c1'} : {},
      ),
      channelImages: images,
      imagePicker: picker,
      imageCropper: cropper,
      imageUrl: urlOf,
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
  }

  Finder editAvatar() => find.byTooltip('Modifica la foto del canale');
  Finder editCover() => find.byTooltip('Modifica la copertina');

  group('matite', () {
    testWidgets('chi non è proprietario vede le immagini e basta', (
      tester,
    ) async {
      await openChannel(tester, owner: false);

      expect(find.byType(ChannelCover), findsOneWidget);
      expect(editAvatar(), findsNothing);
      expect(editCover(), findsNothing);
      expect(find.byType(ChannelImageEditButton), findsNothing);
    });

    testWidgets('il proprietario ha una matita su foto e copertina', (
      tester,
    ) async {
      await openChannel(tester);

      expect(editAvatar(), findsOneWidget);
      expect(editCover(), findsOneWidget);
      expect(find.byType(ChannelImageEditButton), findsNWidgets(2));
    });

    testWidgets('le matite stanno in basso a destra di ogni immagine', (
      tester,
    ) async {
      await openChannel(tester);

      final cover = tester.getRect(find.byType(ChannelCover));
      final coverPencil = tester.getRect(
        find.ancestor(
          of: editCover(),
          matching: find.byType(ChannelImageEditButton),
        ),
      );
      expect(coverPencil.right, greaterThan(cover.right - 24));
      expect(coverPencil.bottom, greaterThan(cover.bottom - 24));
      expect(coverPencil.bottom, lessThanOrEqualTo(cover.bottom));

      final photo = tester.getRect(
        find.descendant(
          of: find.byType(ChannelHeader),
          matching: find.byType(ChannelAvatar),
        ),
      );
      final photoPencil = tester.getRect(
        find.ancestor(
          of: editAvatar(),
          matching: find.byType(ChannelImageEditButton),
        ),
      );
      expect(photoPencil.right, closeTo(photo.right, 8));
      expect(photoPencil.bottom, closeTo(photo.bottom, 8));
    });
  });

  group('finestra', () {
    testWidgets('la foto: galleria e fotocamera, niente "Rimuovi" se non c è', (
      tester,
    ) async {
      await openChannel(tester);

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();

      expect(find.text('Foto del canale'), findsOneWidget);
      expect(find.text('Scegli dalla galleria'), findsOneWidget);
      expect(find.text('Scatta una foto'), findsOneWidget);
      expect(find.text('Rimuovi la foto'), findsNothing);
    });

    testWidgets('con una foto già messa compare "Rimuovi la foto"', (
      tester,
    ) async {
      await openChannel(tester, avatarPath: 'c1/avatar-1.jpg');

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();

      expect(find.text('Rimuovi la foto'), findsOneWidget);
    });

    testWidgets('la copertina ha la sua finestra e la sua rimozione', (
      tester,
    ) async {
      await openChannel(tester, coverPath: 'c1/cover-1.jpg');

      await tester.tap(editCover());
      await tester.pumpAndSettle();

      expect(find.text('Copertina del canale'), findsOneWidget);
      expect(find.text('Rimuovi la copertina'), findsOneWidget);
    });

    testWidgets('Annulla chiude la finestra senza fare niente', (tester) async {
      await openChannel(tester);
      await tester.tap(editAvatar());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(find.text('Foto del canale'), findsNothing);
      expect(picker.sources, isEmpty);
      expect(images.setCalls, isEmpty);
    });
  });

  group('cambiare un immagine', () {
    testWidgets('dalla galleria: scelta, ritaglio quadrato e caricamento', (
      tester,
    ) async {
      await openChannel(tester);

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scegli dalla galleria'));
      await tester.pumpAndSettle();

      expect(picker.sources, [ChannelImageSource.gallery]);
      // Il ritaglio riceve la foto scelta, nella proporzione della foto.
      expect(cropper.calls.single.source, picked);
      expect(cropper.calls.single.kind, ChannelImageKind.avatar);
      // Si carica quello che è uscito dal ritaglio.
      expect(images.setCalls.single.channelId, 'c1');
      expect(images.setCalls.single.kind, ChannelImageKind.avatar);
      expect(images.setCalls.single.bytes, cropped);
      expect(find.text('Foto aggiornata'), findsOneWidget);
    });

    testWidgets('dalla fotocamera', (tester) async {
      await openChannel(tester);

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scatta una foto'));
      await tester.pumpAndSettle();

      expect(picker.sources, [ChannelImageSource.camera]);
      expect(images.setCalls, hasLength(1));
    });

    testWidgets('la copertina si ritaglia nella sua proporzione', (
      tester,
    ) async {
      await openChannel(tester);

      await tester.tap(editCover());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scegli dalla galleria'));
      await tester.pumpAndSettle();

      expect(cropper.calls.single.kind, ChannelImageKind.cover);
      expect(images.setCalls.single.kind, ChannelImageKind.cover);
      expect(find.text('Copertina aggiornata'), findsOneWidget);
    });

    testWidgets('dopo il caricamento la pagina mostra la foto nuova', (
      tester,
    ) async {
      await openChannel(tester);
      expect(networkImage('https://img.test/c1/avatar-1.jpg'), findsNothing);

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scegli dalla galleria'));
      await tester.pumpAndSettle();

      expect(networkImage('https://img.test/c1/avatar-1.jpg'), findsOneWidget);
    });

    testWidgets('dopo il caricamento la pagina mostra la copertina nuova', (
      tester,
    ) async {
      await openChannel(tester);

      await tester.tap(editCover());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scegli dalla galleria'));
      await tester.pumpAndSettle();

      expect(networkImage('https://img.test/c1/cover-1.jpg'), findsOneWidget);
    });

    testWidgets('se non si sceglie nessuna foto non succede niente', (
      tester,
    ) async {
      await openChannel(tester);
      picker.bytes = null;

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scegli dalla galleria'));
      await tester.pumpAndSettle();

      expect(cropper.calls, isEmpty);
      expect(images.setCalls, isEmpty);
    });

    testWidgets('se si rinuncia al ritaglio non si carica niente', (
      tester,
    ) async {
      await openChannel(tester);
      cropper.result = null;

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scegli dalla galleria'));
      await tester.pumpAndSettle();

      expect(cropper.calls, hasLength(1));
      expect(images.setCalls, isEmpty);
      expect(find.text('Foto aggiornata'), findsNothing);
    });

    testWidgets('galleria o fotocamera che non si aprono: messaggio', (
      tester,
    ) async {
      await openChannel(tester);
      picker.error = PlatformException(code: 'photo_access_denied');

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scatta una foto'));
      await tester.pumpAndSettle();

      expect(
        find.text('Non riesco ad aprire la galleria o la fotocamera.'),
        findsOneWidget,
      );
      expect(images.setCalls, isEmpty);
    });

    testWidgets('una foto troppo pesante: messaggio', (tester) async {
      await openChannel(tester);
      picker.error = const ImageFailure(ImageFailureReason.tooLarge);

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scegli dalla galleria'));
      await tester.pumpAndSettle();

      expect(
        find.text('La foto pesa troppo: scegline una sotto i 15 MB.'),
        findsOneWidget,
      );
      expect(images.setCalls, isEmpty);
    });

    testWidgets(
      'errore nel caricamento: messaggio, niente cambia, si riprova',
      (
        tester,
      ) async {
        await openChannel(tester);
        images.setError = const NetworkFailure();

        await tester.tap(editAvatar());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Scegli dalla galleria'));
        await tester.pumpAndSettle();

        expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
        expect(networkImage('https://img.test/c1/avatar-1.jpg'), findsNothing);
        expect(find.byType(InlineProgress), findsNothing);

        images.setError = null;
        await tester.tap(editAvatar());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Scegli dalla galleria'));
        await tester.pumpAndSettle();

        expect(find.text('Foto aggiornata'), findsOneWidget);
      },
    );

    testWidgets(
      'non proprietario nel database (42501): messaggio di permesso',
      (
        tester,
      ) async {
        await openChannel(tester);
        images.setError = const PermissionFailure();

        await tester.tap(editAvatar());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Scegli dalla galleria'));
        await tester.pumpAndSettle();

        expect(
          find.text('Non hai i permessi per eseguire questa azione'),
          findsOneWidget,
        );
      },
    );

    testWidgets('mentre carica l immagine mostra l avanzamento e non riparte', (
      tester,
    ) async {
      await openChannel(tester);
      images.gate = Completer<void>();

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scegli dalla galleria'));
      // Il tempo che la finestra si chiuda del tutto.
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(InlineProgress), findsOneWidget);

      // Un secondo tocco mentre carica non fa niente.
      await tester.tap(editAvatar());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Foto del canale'), findsNothing);

      images.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(InlineProgress), findsNothing);
      expect(images.setCalls, hasLength(1));
    });

    testWidgets('la copertina mostra l avanzamento solo sulla copertina', (
      tester,
    ) async {
      await openChannel(tester);
      images.gate = Completer<void>();

      await tester.tap(editCover());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scegli dalla galleria'));
      await tester.pump(const Duration(milliseconds: 100));

      final progress = tester.getCenter(find.byType(InlineProgress));
      final cover = tester.getRect(find.byType(ChannelCover));
      expect(cover.contains(progress), isTrue);

      images.gate!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('togliere un immagine', () {
    testWidgets('chiede conferma e poi toglie la foto', (tester) async {
      await openChannel(tester, avatarPath: 'c1/avatar-1.jpg');
      expect(networkImage('https://img.test/c1/avatar-1.jpg'), findsOneWidget);

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rimuovi la foto'));
      await tester.pumpAndSettle();
      expect(find.text('Rimuovere la foto?'), findsOneWidget);
      expect(find.text('Tornerà quella predefinita.'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Rimuovi'));
      await tester.pumpAndSettle();

      expect(images.removeCalls.single.channelId, 'c1');
      expect(images.removeCalls.single.kind, ChannelImageKind.avatar);
      expect(find.text('Foto rimossa'), findsOneWidget);
      expect(networkImage('https://img.test/c1/avatar-1.jpg'), findsNothing);
    });

    testWidgets('toglie la copertina e torna quella di default', (
      tester,
    ) async {
      await openChannel(tester, coverPath: 'c1/cover-1.jpg');

      await tester.tap(editCover());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rimuovi la copertina'));
      await tester.pumpAndSettle();
      expect(find.text('Rimuovere la copertina?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Rimuovi'));
      await tester.pumpAndSettle();

      expect(images.removeCalls.single.kind, ChannelImageKind.cover);
      expect(find.text('Copertina rimossa'), findsOneWidget);
      expect(networkImage('https://img.test/c1/cover-1.jpg'), findsNothing);
      expect(find.byType(ChannelCover), findsOneWidget);
    });

    testWidgets('Annulla nella conferma non toglie niente', (tester) async {
      await openChannel(tester, avatarPath: 'c1/avatar-1.jpg');

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rimuovi la foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(images.removeCalls, isEmpty);
      expect(networkImage('https://img.test/c1/avatar-1.jpg'), findsOneWidget);
    });

    testWidgets('errore: messaggio e la foto resta', (tester) async {
      await openChannel(tester, avatarPath: 'c1/avatar-1.jpg');
      images.removeError = const NetworkFailure();

      await tester.tap(editAvatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rimuovi la foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Rimuovi'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(networkImage('https://img.test/c1/avatar-1.jpg'), findsOneWidget);
    });
  });

  group('negli elenchi', () {
    testWidgets('la foto del canale compare anche nell elenco', (tester) async {
      final channel = makeChannel(
        1,
        name: 'Spotted Pisa',
        avatarPath: 'c1/avatar-9.jpg',
      );
      await pumpApp(
        tester,
        channels: FakeChannelsRepository(channels: [channel]),
        imageUrl: urlOf,
      );

      await tester.tap(find.byIcon(Icons.tag_rounded));
      await tester.pumpAndSettle();

      expect(networkImage('https://img.test/c1/avatar-9.jpg'), findsOneWidget);
    });

    testWidgets('un canale senza foto ha l iniziale', (tester) async {
      await pumpApp(
        tester,
        channels: FakeChannelsRepository(
          channels: [makeChannel(1, name: 'Spotted Pisa')],
        ),
        imageUrl: urlOf,
      );

      await tester.tap(find.byIcon(Icons.tag_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(find.text('S'), findsWidgets);
    });
  });

  group('eliminazione del canale', () {
    Future<void> deleteChannel(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina canale'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Elimina'));
      await tester.pumpAndSettle();
    }

    testWidgets('cancella anche i file delle immagini del canale', (
      tester,
    ) async {
      await openChannel(
        tester,
        avatarPath: 'c1/avatar-1.jpg',
        coverPath: 'c1/cover-2.jpg',
      );

      await deleteChannel(tester);

      expect(images.deleteCalls.single, [
        'c1/avatar-1.jpg',
        'c1/cover-2.jpg',
      ]);
      expect(channels.deleteCalls, ['c1']);
    });

    testWidgets('con una sola immagine cancella solo quella', (tester) async {
      await openChannel(tester, coverPath: 'c1/cover-2.jpg');

      await deleteChannel(tester);

      expect(images.deleteCalls.single, ['c1/cover-2.jpg']);
    });

    testWidgets('senza immagini non tocca lo storage', (tester) async {
      await openChannel(tester);

      await deleteChannel(tester);

      expect(images.deleteCalls, isEmpty);
      expect(channels.deleteCalls, ['c1']);
    });
  });

  group('ChannelCover', () {
    Widget host(double width, {double? height}) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ChannelCover(height: height),
          ),
        ),
      ),
    );

    testWidgets('su un telefono segue la proporzione 8:3', (tester) async {
      await tester.pumpWidget(host(360));

      expect(tester.getSize(find.byType(ChannelCover)).height, 135);
    });

    testWidgets('su uno schermo largo non supera l altezza massima', (
      tester,
    ) async {
      await tester.pumpWidget(host(1200));

      expect(
        tester.getSize(find.byType(ChannelCover)).height,
        ChannelCover.maxHeight,
      );
    });

    testWidgets('un altezza fissa vince sulla proporzione', (tester) async {
      await tester.pumpWidget(host(360, height: 100));

      expect(tester.getSize(find.byType(ChannelCover)).height, 100);
    });

    test('heightFor calcola la proporzione e il tetto', () {
      expect(ChannelCover.heightFor(480), 180);
      expect(ChannelCover.heightFor(10000), ChannelCover.maxHeight);
    });
  });
}
