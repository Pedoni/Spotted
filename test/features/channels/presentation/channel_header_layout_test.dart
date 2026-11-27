import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_cover.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_header.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_image_edit_button.dart';
import 'package:spotted/l10n/app_localizations.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(
    1,
    name: 'Spotted Pisa',
    description: 'Gli spot di Pisa',
    topicId: 't-uni',
    place: 'Pisa (PI)',
  );

  Future<void> openChannel(
    WidgetTester tester, {
    Size size = const Size(400, 800),
    int count = 120,
    bool subscribed = false,
    bool owner = false,
  }) async {
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      subscriptions: FakeSubscriptionsRepository(
        channels: [channel],
        subscribedIds: subscribed ? {'c1'} : {},
        counts: {'c1': count},
      ),
      moderation: FakeModerationRepository(
        ownedChannelIds: owner ? {'c1'} : {},
      ),
      screenSize: size,
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
  }

  Rect photoRect(WidgetTester tester) => tester.getRect(
    find.descendant(
      of: find.byType(ChannelHeader),
      matching: find.byType(ChannelAvatar),
    ),
  );

  Rect inHeader(WidgetTester tester, Finder finder) => tester.getRect(
    find.descendant(of: find.byType(ChannelHeader), matching: finder),
  );

  Rect badgeRect(WidgetTester tester) =>
      tester.getRect(find.byType(SubscribersBadge));

  group('numero di iscritti sulla copertina, in basso a destra', () {
    testWidgets('sta dentro la copertina, in basso a destra', (tester) async {
      await openChannel(tester);

      final cover = tester.getRect(find.byType(ChannelCover));
      final badge = badgeRect(tester);

      expect(badge.right, lessThanOrEqualTo(cover.right));
      expect(cover.right - badge.right, lessThanOrEqualTo(16));
      expect(badge.bottom, lessThan(cover.bottom));
      expect(cover.bottom - badge.bottom, lessThanOrEqualTo(24));
      // Sta nella metà destra, non in mezzo alla copertina.
      expect(badge.left, greaterThan(cover.center.dx));
    });

    testWidgets('ha prima il numero e poi l icona del gruppo', (tester) async {
      await openChannel(tester);

      final number = tester.getRect(
        find.descendant(
          of: find.byType(SubscribersBadge),
          matching: find.text('120'),
        ),
      );
      final icon = tester.getRect(
        find.descendant(
          of: find.byType(SubscribersBadge),
          matching: find.byIcon(Icons.groups_rounded),
        ),
      );

      expect(number.right, lessThanOrEqualTo(icon.left));
      expect((number.center.dy - icon.center.dy).abs(), lessThan(6));
    });

    testWidgets('fino a 999 mostra il numero intero', (tester) async {
      await openChannel(tester, count: 999);

      expect(
        find.descendant(
          of: find.byType(SubscribersBadge),
          matching: find.text('999'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('da 1000 usa la K', (tester) async {
      await openChannel(tester, count: 1000);

      expect(find.text('1K'), findsOneWidget);
    });

    testWidgets('con la K va a scaglioni di un decimale', (tester) async {
      await openChannel(tester, count: 1234);

      expect(find.text('1.2K'), findsOneWidget);
    });

    testWidgets('da un milione usa la M', (tester) async {
      await openChannel(tester, count: 1100000);

      expect(find.text('1.1M'), findsOneWidget);
    });

    testWidgets('il numero esatto è nel suggerimento e per i lettori di '
        'schermo', (tester) async {
      await openChannel(tester, count: 1234);

      final handle = tester.ensureSemantics();
      expect(find.byTooltip('1234 iscritti'), findsOneWidget);
      expect(find.bySemanticsLabel('1234 iscritti'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('seguendo il numero sale', (tester) async {
      await openChannel(tester, count: 1099);
      expect(find.text('1K'), findsOneWidget);

      await tester.tap(
        find.widgetWithIcon(FilledButton, Icons.person_add_rounded),
      );
      await tester.pumpAndSettle();

      // 1100 iscritti: scatta lo scaglione successivo.
      expect(find.text('1.1K'), findsOneWidget);
    });

    testWidgets('il proprietario ha la matita sulla copertina: il numero '
        'le sta a sinistra, senza coprirla', (tester) async {
      await openChannel(tester, owner: true);

      final badge = badgeRect(tester);
      final pencil = tester.getRect(
        find.byTooltip('Modifica la copertina'),
      );

      expect(pencil.size.width, ChannelImageEditButton.size);
      expect(badge.right, lessThanOrEqualTo(pencil.left));
      expect(badge.overlaps(pencil), isFalse);
      // Alla stessa altezza.
      expect((badge.center.dy - pencil.center.dy).abs(), lessThan(8));
    });

    testWidgets('non c è più il testo degli iscritti vicino al pulsante', (
      tester,
    ) async {
      await openChannel(tester);

      expect(find.text('120 iscritti'), findsNothing);
    });
  });

  group('pulsante Segui sotto la copertina, a destra della foto', () {
    testWidgets('sta alla destra della foto, nella fascia sotto la copertina', (
      tester,
    ) async {
      await openChannel(tester);

      final cover = tester.getRect(find.byType(ChannelCover));
      final photo = photoRect(tester);
      final button = inHeader(
        tester,
        find.widgetWithIcon(FilledButton, Icons.person_add_rounded),
      );

      expect(button.left, greaterThan(photo.right));
      expect(button.top, greaterThanOrEqualTo(cover.bottom));
      expect(button.bottom, lessThanOrEqualTo(photo.bottom));
      expect(button.right, 400 - 16);
    });

    testWidgets('Smetti di seguire sta nello stesso posto', (tester) async {
      await openChannel(tester, subscribed: true);

      final button = inHeader(
        tester,
        find.widgetWithIcon(OutlinedButton, Icons.person_remove_rounded),
      );

      expect(button.left, greaterThan(photoRect(tester).right));
      expect(button.right, 400 - 16);
    });

    testWidgets('su uno schermo stretto non va in overflow', (tester) async {
      await openChannel(
        tester,
        size: const Size(320, 640),
        subscribed: true,
        count: 1234567,
      );

      expect(tester.takeException(), isNull);
      final button = inHeader(
        tester,
        find.widgetWithIcon(OutlinedButton, Icons.person_remove_rounded),
      );
      expect(button.right, lessThanOrEqualTo(320 - 16));
      expect(button.left, greaterThan(photoRect(tester).right));
      expect(find.text('1.2M'), findsOneWidget);
    });

    testWidgets('il pulsante Segui funziona dal suo nuovo posto', (
      tester,
    ) async {
      await openChannel(tester);

      await tester.tap(
        find.widgetWithIcon(FilledButton, Icons.person_add_rounded),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_remove_rounded), findsOneWidget);
      expect(find.text('121'), findsOneWidget);
    });
  });

  group('spazi stretti', () {
    testWidgets('tra un elemento e l altro dell intestazione c è poco spazio', (
      tester,
    ) async {
      await openChannel(tester);

      final photo = photoRect(tester);
      final name = inHeader(tester, find.text('Spotted Pisa'));
      final topic = inHeader(tester, find.text('Università'));
      final place = inHeader(tester, find.text('Pisa (PI)'));
      final description = inHeader(tester, find.text('Gli spot di Pisa'));
      final tabs = tester.getRect(find.byType(TabBar));

      // Il nome segue la foto, senza il vuoto di prima.
      expect(name.top - photo.bottom, lessThanOrEqualTo(12));
      // Argomento e luogo sono sotto il nome, vicini.
      // (i rettangoli sono quelli dei testi: dentro un chip c'è il suo margine)
      expect(topic.top - name.bottom, lessThanOrEqualTo(24));
      final chipsBottom = topic.bottom > place.bottom
          ? topic.bottom
          : place.bottom;
      // Descrizione e barra delle schede sono vicine.
      expect(description.top - chipsBottom, lessThanOrEqualTo(24));
      expect(tabs.top - description.bottom, lessThan(24));
    });
  });

  group('ChannelHeader', () {
    Future<double> nameTop(
      WidgetTester tester, {
      Widget? follow,
      int? subscriberCount,
    }) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ChannelHeader(
                  channel: channel,
                  follow: follow,
                  subscriberCount: subscriberCount,
                ),
              ),
            ),
          ),
        ),
      );
      return tester.getTopLeft(find.text('Spotted Pisa')).dy;
    }

    testWidgets('senza i dati sugli iscritti l intestazione non cambia '
        'altezza: la fascia resta vuota', (tester) async {
      final without = await nameTop(tester);
      final withData = await nameTop(
        tester,
        subscriberCount: 5,
        follow: FilledButton(onPressed: () {}, child: const Text('+ Segui')),
      );

      expect(withData, without);
    });

    testWidgets('senza i dati non compare né il numero né il pulsante', (
      tester,
    ) async {
      await nameTop(tester);

      expect(find.byType(SubscribersBadge), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('con zero iscritti mostra 0', (tester) async {
      await nameTop(tester, subscriberCount: 0);

      expect(find.text('0'), findsOneWidget);
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    });
  });
}
