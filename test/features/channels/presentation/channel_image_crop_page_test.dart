import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/features/channels/presentation/services/channel_image_cropper.dart';
import 'package:spotted/l10n/app_localizations.dart';

void main() {
  /// Un PNG di [width]x[height], di un colore solo.
  Uint8List png(int width, int height) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(200, 30, 90));
    return img.encodePng(image);
  }

  /// Apre il ritaglio come fa l'app (pagina a schermo intero) e tiene il
  /// risultato.
  Future<void> openCrop(
    WidgetTester tester,
    ChannelImageKind kind,
    List<Uint8List?> results,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  final result = await const PageChannelImageCropper().crop(
                    context,
                    png(600, 400),
                    kind,
                  );
                  results.add(result);
                },
                child: const Text('Apri'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    // La pagina entra dal basso: il tempo che finisca.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// La pagina carica la foto in modo asincrono: serve far girare il tempo
  /// vero, non solo quello finto dei test.
  Future<void> letImageLoad(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('la foto ha il titolo, il suggerimento e il pulsante', (
    tester,
  ) async {
    await openCrop(tester, ChannelImageKind.avatar, []);

    expect(find.text('Ritaglia la foto'), findsOneWidget);
    expect(find.text('Trascina e ingrandisci con le dita.'), findsOneWidget);
    expect(find.text('Usa questa immagine'), findsOneWidget);
  });

  testWidgets('la copertina ha il suo titolo', (tester) async {
    await openCrop(tester, ChannelImageKind.cover, []);

    expect(find.text('Ritaglia la copertina'), findsOneWidget);
  });

  testWidgets('il ritaglio ha la proporzione della foto: quadrata', (
    tester,
  ) async {
    await openCrop(tester, ChannelImageKind.avatar, []);

    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, 1);
    // La cornice sta ferma e si muove la foto.
    expect(crop.interactive, isTrue);
    expect(crop.fixCropRect, isTrue);
  });

  testWidgets('il ritaglio della copertina è 8:3', (tester) async {
    await openCrop(tester, ChannelImageKind.cover, []);

    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, closeTo(8 / 3, 0.001));
  });

  testWidgets('il pulsante aspetta che la foto sia caricata', (tester) async {
    await openCrop(tester, ChannelImageKind.avatar, []);

    final before = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(before.onPressed, isNull);

    await letImageLoad(tester);

    final after = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(after.onPressed, isNotNull);
  });

  testWidgets('"Usa questa immagine" restituisce la parte ritagliata', (
    tester,
  ) async {
    final results = <Uint8List?>[];
    await openCrop(tester, ChannelImageKind.avatar, results);
    await letImageLoad(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(results, hasLength(1));
    final out = results.single!;
    // La parte ritagliata è quadrata, come la foto.
    final decoded = img.decodeImage(out)!;
    expect(decoded.width, decoded.height);
  });

  testWidgets('chiudere la pagina senza confermare restituisce null', (
    tester,
  ) async {
    final results = <Uint8List?>[];
    await openCrop(tester, ChannelImageKind.avatar, results);

    await tester.tap(find.byType(CloseButton));
    await tester.pump(const Duration(milliseconds: 500));

    expect(results, [null]);
  });
}
