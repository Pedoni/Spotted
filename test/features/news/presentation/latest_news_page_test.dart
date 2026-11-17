import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

import '../../../helpers/fake_news.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  /// Home → freccia di "Ultime news".
  Future<void> openPage(WidgetTester tester, FakeNewsRepository news) async {
    await pumpApp(tester, news: news);
    await tester.tap(find.byTooltip('Visualizza tutti'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra tutte le news con il canale', (tester) async {
    final news = FakeNewsRepository()
      ..followed = [
        makeNews(1, title: 'Orari estivi', channelName: 'Spotted Pisa'),
        makeNews(2, title: 'Nuova sede', channelName: 'Altro canale'),
      ];
    await openPage(tester, news);

    expect(find.text('Orari estivi'), findsOneWidget);
    expect(find.text('Nuova sede'), findsOneWidget);
    expect(find.textContaining('Spotted Pisa'), findsOneWidget);
    expect(find.textContaining('Altro canale'), findsOneWidget);
  });

  testWidgets('scorrendo in fondo carica la pagina successiva', (tester) async {
    final news = FakeNewsRepository()
      ..followed = [for (var i = 1; i <= 25; i++) makeNews(i)];
    await openPage(tester, news);

    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -6000));
      await tester.pumpAndSettle();
    }

    expect(
      news.followedCalls.map((c) => c.offset),
      containsAllInOrder([0, 20]),
    );
    expect(find.text('News 25'), findsOneWidget);
  });

  testWidgets('toccare una news la apre', (tester) async {
    final news = FakeNewsRepository(news: [makeNews(1, title: 'Orari estivi')])
      ..followed = [makeNews(1, title: 'Orari estivi')];
    await openPage(tester, news);

    await tester.tap(find.text('Orari estivi'));
    await tester.pumpAndSettle();

    expect(find.text('Testo della news 1'), findsOneWidget);
  });

  testWidgets('toccare il nome del canale apre il canale', (tester) async {
    final channel = makeChannel(1, name: 'Spotted Pisa');
    final news = FakeNewsRepository()
      ..followed = [makeNews(1, channelName: 'Spotted Pisa')];
    await pumpApp(
      tester,
      news: news,
      channels: FakeChannelsRepository(channels: [channel]),
    );
    await tester.tap(find.byTooltip('Visualizza tutti'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Spotted Pisa'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Tab, 'News'), findsOneWidget);
  });

  testWidgets('errore: messaggio e Riprova', (tester) async {
    final news = FakeNewsRepository()..followed = [makeNews(1)];
    await openPage(tester, news);
    news
      ..followedError = const NetworkFailure()
      ..followed = [makeNews(1, title: 'Orari estivi')];

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    news.followedError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Orari estivi'), findsOneWidget);
  });
}
