import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/brand_blobs.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_cover.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_header.dart';
import 'package:spotted/l10n/app_localizations.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(
    1,
    name: 'Spotted Pisa',
    description: 'Gli spot di Pisa',
  );

  Future<void> openChannel(
    WidgetTester tester, {
    FakeSpotsRepository? spots,
  }) async {
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots: spots,
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
  }

  group('copertina e foto', () {
    testWidgets('in cima c è la copertina di default, uguale per tutti', (
      tester,
    ) async {
      await openChannel(tester);

      expect(find.byType(ChannelCover), findsOneWidget);
      expect(find.byType(BrandBlobs), findsOneWidget);
      final cover = tester.getRect(find.byType(ChannelCover));
      expect(cover.width, 800);
      // Segue la proporzione 8:3 ma non supera l'altezza massima.
      expect(cover.height, ChannelCover.heightFor(800));
      expect(cover.height, ChannelCover.maxHeight);
    });

    testWidgets('la foto è quadrata e sovrappone la copertina, a sinistra', (
      tester,
    ) async {
      await openChannel(tester);

      final cover = tester.getRect(find.byType(ChannelCover));
      final photo = tester.getRect(
        find.descendant(
          of: find.byType(ChannelHeader),
          matching: find.byType(ChannelAvatar),
        ),
      );

      expect(photo.width, ChannelHeader.avatarSize);
      expect(photo.height, photo.width);
      // Esce dalla copertina verso il basso.
      expect(photo.top, lessThan(cover.bottom));
      expect(photo.bottom, greaterThan(cover.bottom));
      expect(photo.left, 24);
    });

    testWidgets('la foto mostra l iniziale del canale e non copre il nome', (
      tester,
    ) async {
      await openChannel(tester);

      final photo = tester.getRect(
        find.descendant(
          of: find.byType(ChannelHeader),
          matching: find.byType(ChannelAvatar),
        ),
      );
      final name = tester.getRect(
        find.descendant(
          of: find.byType(ChannelHeader),
          matching: find.text('Spotted Pisa'),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(ChannelAvatar),
          matching: find.text('S'),
        ),
        findsWidgets,
      );
      expect(name.top, greaterThanOrEqualTo(photo.bottom));
    });

    testWidgets('anche nell elenco la foto è la stessa del canale', (
      tester,
    ) async {
      await pumpApp(
        tester,
        channels: FakeChannelsRepository(channels: [channel]),
      );
      await tester.tap(find.byIcon(Icons.tag_rounded));
      await tester.pumpAndSettle();
      final inList = tester
          .widget<ChannelAvatar>(find.byType(ChannelAvatar).first)
          .seed;

      await tester.tap(find.text('Spotted Pisa'));
      await tester.pumpAndSettle();
      final inChannel = tester
          .widget<ChannelAvatar>(
            find.descendant(
              of: find.byType(ChannelHeader),
              matching: find.byType(ChannelAvatar),
            ),
          )
          .seed;

      expect(inChannel, inList);
    });
  });

  group('ChannelCover', () {
    Widget host(Widget child) => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

    testWidgets('senza immagine c è la copertina di marca', (tester) async {
      await tester.pumpWidget(host(const ChannelCover()));

      expect(find.byType(BrandBlobs), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('con un immagine la usa; se non si carica resta quella di '
        'marca', (tester) async {
      await tester.pumpWidget(
        host(const ChannelCover(imageUrl: 'https://esempio.it/cover.jpg')),
      );
      expect(find.byType(Image), findsOneWidget);

      // Nei test le richieste di rete falliscono: resta la copertina di marca.
      await tester.pumpAndSettle();
      expect(find.byType(BrandBlobs), findsOneWidget);
    });

    testWidgets('l altezza si può scegliere', (tester) async {
      await tester.pumpWidget(host(const ChannelCover(height: 100)));

      expect(tester.getSize(find.byType(ChannelCover)).height, 100);
    });
  });

  group('schede', () {
    testWidgets('sotto l intestazione ci sono Spots, Eventi e News', (
      tester,
    ) async {
      await openChannel(tester);

      expect(find.byType(TabBar), findsOneWidget);
      for (final label in ['Spots', 'Eventi', 'News']) {
        expect(
          find.descendant(of: find.byType(TabBar), matching: find.text(label)),
          findsOneWidget,
        );
      }
      final subscribers = tester.getRect(find.byTooltip('Nessun iscritto'));
      final tabs = tester.getRect(find.byType(TabBar));
      expect(tabs.top, greaterThan(subscribers.bottom));
    });

    testWidgets('parte da Spots: gli spot e il pulsante Pubblica', (
      tester,
    ) async {
      await openChannel(
        tester,
        spots: FakeSpotsRepository(spots: [makeSpot(1)]),
      );

      expect(find.text('Spot 1'), findsOneWidget);
      expect(find.text('Pubblica uno spot'), findsOneWidget);
      expect(find.text('Nessun evento in programma'), findsNothing);
    });

    testWidgets('Eventi dice che non c è niente e nasconde gli spot', (
      tester,
    ) async {
      await openChannel(
        tester,
        spots: FakeSpotsRepository(spots: [makeSpot(1)]),
      );

      await tester.tap(find.text('Eventi'));
      await tester.pumpAndSettle();

      expect(find.text('Nessun evento in programma'), findsOneWidget);
      expect(
        find.text('Qui compariranno gli eventi del canale.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.event_rounded), findsOneWidget);
      expect(find.text('Spot 1'), findsNothing);
      // Pubblicare uno spot ha senso solo nella scheda Spots.
      expect(find.text('Pubblica uno spot'), findsNothing);
    });

    testWidgets('News dice che non c è niente', (tester) async {
      await openChannel(tester);

      await tester.tap(find.text('News'));
      await tester.pumpAndSettle();

      expect(find.text('Ancora nessuna news'), findsOneWidget);
      expect(
        find.text('Qui compariranno le novità del canale.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.newspaper_rounded), findsOneWidget);
    });

    testWidgets('tornando su Spots tornano gli spot e il pulsante', (
      tester,
    ) async {
      await openChannel(
        tester,
        spots: FakeSpotsRepository(spots: [makeSpot(1)]),
      );
      await tester.tap(find.text('News'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spots'));
      await tester.pumpAndSettle();

      expect(find.text('Spot 1'), findsOneWidget);
      expect(find.text('Pubblica uno spot'), findsOneWidget);
      expect(find.text('Ancora nessuna news'), findsNothing);
    });

    testWidgets('la barra delle schede resta ferma in cima scorrendo', (
      tester,
    ) async {
      await openChannel(
        tester,
        spots: FakeSpotsRepository(spots: List.generate(20, makeSpot)),
      );
      final before = tester.getRect(find.byType(TabBar)).top;

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();

      final after = tester.getRect(find.byType(TabBar)).top;
      expect(after, lessThan(before));
      // Sta sotto la barra dell'app, non esce dallo schermo.
      expect(after, greaterThanOrEqualTo(0));
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('Eventi e News restano centrati nello spazio rimasto', (
      tester,
    ) async {
      await openChannel(tester);
      await tester.tap(find.text('Eventi'));
      await tester.pumpAndSettle();

      final empty = tester.getCenter(find.byIcon(Icons.event_rounded));
      final tabs = tester.getRect(find.byType(TabBar));
      final screen = tester.getSize(find.byType(Scaffold).last);
      final above = empty.dy - tabs.bottom;
      final below = screen.height - empty.dy;

      expect(above, greaterThan(0));
      expect((above - below).abs(), lessThan(120));
    });
  });
}
