import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/news/presentation/widgets/latest_news_section.dart';
import 'package:spotted/features/spots/presentation/widgets/my_spots_carousel.dart';

import '../../helpers/fake_news.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('senza spot propri: messaggio che invita a pubblicare', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('I miei spot'), findsOneWidget);
    expect(find.text('Non hai ancora pubblicato spot'), findsOneWidget);
    expect(find.textContaining('Apri un canale'), findsOneWidget);
    // Non c'è niente da vedere: niente freccia.
    expect(find.byTooltip('Visualizza tutti'), findsNothing);
  });

  testWidgets('con spot propri mostra il carosello e non il feed dei canali', (
    tester,
  ) async {
    final spots = FakeSpotsRepository(
      mine: [makeMySpot(1)],
      followed: [makeMySpot(2)],
    );
    await pumpApp(tester, spots: spots);

    expect(find.byType(MySpotCard), findsOneWidget);
    expect(find.text('Spot 1'), findsOneWidget);
    expect(find.text('Spot 2'), findsNothing);
    expect(spots.followedCalls, isEmpty);
  });

  testWidgets('tirando giù si ricaricano i miei spot', (tester) async {
    final spots = FakeSpotsRepository(mine: [makeMySpot(1)]);
    await pumpApp(tester, spots: spots);
    expect(spots.mineCalls, hasLength(1));

    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(spots.mineCalls, hasLength(2));
  });

  testWidgets('non c è il pulsante Pubblica', (tester) async {
    await pumpApp(tester, spots: FakeSpotsRepository(mine: [makeMySpot(1)]));

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Pubblica'), findsNothing);
  });

  group('Ultime news', () {
    testWidgets('mostra le news dei canali seguiti, con canale e titolo', (
      tester,
    ) async {
      final news = FakeNewsRepository()
        ..followed = [
          makeNews(1, title: 'Orari estivi', channelName: 'Spotted Pisa'),
          makeNews(2, title: 'Nuova sede'),
        ];
      await pumpApp(tester, news: news);

      expect(find.text('Ultime news'), findsOneWidget);
      expect(find.byType(NewsCarouselCard), findsNWidgets(2));
      expect(find.text('Orari estivi'), findsOneWidget);
      expect(find.text('Testo della news 1'), findsOneWidget);
      expect(find.textContaining('Spotted Pisa'), findsOneWidget);
      expect(find.byTooltip('Visualizza tutti'), findsOneWidget);
    });

    testWidgets('senza news la sezione c è e lo dice, senza freccia', (
      tester,
    ) async {
      await pumpApp(tester, news: FakeNewsRepository());

      expect(find.text('Ultime news'), findsOneWidget);
      expect(find.text('Nessuna news dai canali che segui'), findsOneWidget);
      expect(
        find.text('Qui compariranno le news dei canali che segui.'),
        findsOneWidget,
      );
      expect(find.byType(NewsCarouselCard), findsNothing);
      // I miei spot ha la sua freccia solo con degli spot: qui nessuna.
      expect(find.byTooltip('Visualizza tutti'), findsNothing);
    });

    testWidgets('senza canali seguiti il messaggio è lo stesso', (
      tester,
    ) async {
      await pumpApp(
        tester,
        news: FakeNewsRepository(),
        subscriptions: FakeSubscriptionsRepository(),
      );

      expect(find.text('Ultime news'), findsOneWidget);
      expect(find.text('Nessuna news dai canali che segui'), findsOneWidget);
    });

    testWidgets('mostra al massimo 5 card e poi Visualizza tutti', (
      tester,
    ) async {
      final news = FakeNewsRepository()
        ..followed = [for (var i = 1; i <= 7; i++) makeNews(i)];
      await pumpApp(tester, news: news);

      await tester.drag(find.byType(ListView).last, const Offset(-3000, 0));
      await tester.pumpAndSettle();

      expect(find.text('Visualizza tutti'), findsOneWidget);
      // L'ultima news mostrata è la quinta.
      expect(find.text('News 5'), findsOneWidget);
      expect(find.text('News 6'), findsNothing);
      expect(find.text('News 7'), findsNothing);
    });

    testWidgets('con 5 news o meno non c è la card Visualizza tutti', (
      tester,
    ) async {
      final news = FakeNewsRepository()
        ..followed = [for (var i = 1; i <= 5; i++) makeNews(i)];
      await pumpApp(tester, news: news);

      await tester.drag(find.byType(ListView).last, const Offset(-3000, 0));
      await tester.pumpAndSettle();

      expect(find.text('Visualizza tutti'), findsNothing);
    });

    testWidgets('toccare una card apre la news', (tester) async {
      final news = FakeNewsRepository(
        news: [makeNews(1, title: 'Orari estivi')],
      )..followed = [makeNews(1, title: 'Orari estivi')];
      await pumpApp(tester, news: news);

      await tester.tap(find.text('Orari estivi'));
      await tester.pumpAndSettle();

      expect(find.text('News'), findsOneWidget);
      expect(find.text('Testo della news 1'), findsOneWidget);
    });

    testWidgets('la freccia apre l elenco completo', (tester) async {
      final news = FakeNewsRepository()
        ..followed = [for (var i = 1; i <= 7; i++) makeNews(i)];
      await pumpApp(tester, news: news);

      await tester.tap(find.byTooltip('Visualizza tutti'));
      await tester.pumpAndSettle();

      expect(find.text('Ultime news'), findsOneWidget);
      expect(find.text('News 1'), findsOneWidget);
      expect(find.byType(NewsCarouselCard), findsNothing);
    });

    testWidgets('errore: messaggio e Riprova, senza toccare i miei spot', (
      tester,
    ) async {
      final news = FakeNewsRepository()
        ..followed = [makeNews(1, title: 'Orari estivi')]
        ..followedError = const NetworkFailure();
      await pumpApp(
        tester,
        news: news,
        spots: FakeSpotsRepository(mine: [makeMySpot(1)]),
      );

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('Spot 1'), findsOneWidget);

      news.followedError = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(find.text('Orari estivi'), findsOneWidget);
    });

    testWidgets('tirando giù si ricaricano anche le news', (tester) async {
      final news = FakeNewsRepository()..followed = [makeNews(1)];
      final spots = FakeSpotsRepository(mine: [makeMySpot(1)]);
      await pumpApp(tester, news: news, spots: spots);
      expect(news.followedCalls, hasLength(1));

      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(news.followedCalls, hasLength(2));
      expect(spots.mineCalls, hasLength(2));
    });

    testWidgets('se le news falliscono, ricaricare non dà errori', (
      tester,
    ) async {
      final news = FakeNewsRepository()
        ..followed = [makeNews(1)]
        ..followedError = const NetworkFailure();
      await pumpApp(tester, news: news);

      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
    });
  });

  group('Ultime news: quando si ricaricano da sole', () {
    final channel = makeChannel(1, name: 'Spotted Pisa');

    Future<void> openChannel(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.tag_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spotted Pisa'));
      await tester.pumpAndSettle();
    }

    /// Torna alla Home: finché non è visibile le sezioni restano in pausa e si
    /// ricaricano solo quando ricompare.
    Future<void> backToHome(WidgetTester tester) async {
      final back = find.byTooltip('Indietro');
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byIcon(Icons.home_rounded));
      await tester.pumpAndSettle();
    }

    testWidgets('seguendo un canale', (tester) async {
      final news = FakeNewsRepository();
      await pumpApp(
        tester,
        news: news,
        channels: FakeChannelsRepository(channels: [channel]),
        subscriptions: FakeSubscriptionsRepository(channels: [channel]),
      );
      expect(news.followedCalls, hasLength(1));

      await openChannel(tester);
      await tester.tap(find.text('Segui'));
      await tester.pumpAndSettle();
      await backToHome(tester);

      expect(news.followedCalls, hasLength(2));
    });

    testWidgets('smettendo di seguire un canale', (tester) async {
      final news = FakeNewsRepository();
      await pumpApp(
        tester,
        news: news,
        channels: FakeChannelsRepository(channels: [channel]),
        subscriptions: FakeSubscriptionsRepository(
          channels: [channel],
          subscribedIds: {'c1'},
        ),
      );

      await openChannel(tester);
      await tester.tap(find.text('Smetti di seguire'));
      await tester.pumpAndSettle();
      await backToHome(tester);

      expect(news.followedCalls, hasLength(2));
    });

    testWidgets('pubblicando una news', (tester) async {
      final news = FakeNewsRepository();
      await pumpApp(
        tester,
        news: news,
        channels: FakeChannelsRepository(channels: [channel]),
        moderation: FakeModerationRepository(ownedChannelIds: {'c1'}),
        screenSize: const Size(800, 1400),
      );
      await openChannel(tester);
      await tester.tap(find.widgetWithText(Tab, 'News'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pubblica una news'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Titolo'),
        'Orari',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Testo'),
        'Testo',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Pubblica'));
      await tester.pumpAndSettle();

      await backToHome(tester);

      expect(news.createCalls, hasLength(1));
      expect(news.followedCalls, hasLength(2));
    });

    testWidgets('eliminando il canale', (tester) async {
      final news = FakeNewsRepository();
      await pumpApp(
        tester,
        news: news,
        channels: FakeChannelsRepository(channels: [channel], mine: [channel]),
        moderation: FakeModerationRepository(ownedChannelIds: {'c1'}),
        screenSize: const Size(800, 1400),
      );
      await openChannel(tester);
      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina canale'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Elimina'));
      await tester.pumpAndSettle();
      await backToHome(tester);

      expect(news.followedCalls, hasLength(2));
    });
  });
}
