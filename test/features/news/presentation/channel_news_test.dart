import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/widgets/empty_state.dart';

import '../../../helpers/fake_news.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  /// Canali → il canale → scheda News.
  Future<void> openNewsTab(
    WidgetTester tester,
    FakeNewsRepository news, {
    bool owner = false,
  }) async {
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      news: news,
      moderation: FakeModerationRepository(
        ownedChannelIds: owner ? {'c1'} : {},
      ),
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'News'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra le news del canale, con il testo accorciato', (
    tester,
  ) async {
    await openNewsTab(
      tester,
      FakeNewsRepository(
        news: [
          makeNews(1, title: 'Orari estivi'),
          makeNews(2, title: 'Nuova sede'),
          makeNews(3, channelId: 'altro', title: 'Di un altro canale'),
        ],
      ),
    );

    expect(find.text('Orari estivi'), findsOneWidget);
    expect(find.text('Nuova sede'), findsOneWidget);
    expect(find.text('Testo della news 1'), findsOneWidget);
    expect(find.text('Di un altro canale'), findsNothing);
    // Gli spot non si vedono nella scheda News.
    expect(find.text('Pubblica uno spot'), findsNothing);
  });

  testWidgets('canale senza news: lo dice, al centro, senza pulsante', (
    tester,
  ) async {
    await openNewsTab(tester, FakeNewsRepository());

    expect(find.text('Ancora nessuna news'), findsOneWidget);
    expect(find.text('Qui compariranno le novità del canale.'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Pubblica una news'), findsNothing);
  });

  testWidgets('il proprietario senza news vede lo stesso segnaposto e il FAB, '
      'senza altri pulsanti', (tester) async {
    await openNewsTab(tester, FakeNewsRepository(), owner: true);

    expect(find.text('Ancora nessuna news'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(EmptyState),
        matching: find.byType(FilledButton),
      ),
      findsNothing,
    );
    expect(find.text('Pubblica una news'), findsOneWidget);
  });

  testWidgets('il pulsante Pubblica una news è solo del proprietario', (
    tester,
  ) async {
    await openNewsTab(tester, FakeNewsRepository(news: [makeNews(1)]));
    expect(find.text('Pubblica una news'), findsNothing);
  });

  testWidgets('il proprietario vede il pulsante solo nella scheda News', (
    tester,
  ) async {
    await openNewsTab(
      tester,
      FakeNewsRepository(news: [makeNews(1)]),
      owner: true,
    );
    expect(find.text('Pubblica una news'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Spots'));
    await tester.pumpAndSettle();
    expect(find.text('Pubblica una news'), findsNothing);
    expect(find.text('Pubblica uno spot'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Eventi'));
    await tester.pumpAndSettle();
    expect(find.text('Pubblica una news'), findsNothing);
    expect(find.text('Pubblica uno spot'), findsNothing);
  });

  testWidgets('toccare una news apre il dettaglio con il testo intero', (
    tester,
  ) async {
    await openNewsTab(
      tester,
      FakeNewsRepository(
        news: [makeNews(1, title: 'Orari estivi', body: 'Da lunedì alle 9.')],
      ),
    );

    await tester.tap(find.text('Orari estivi'));
    await tester.pumpAndSettle();

    expect(find.text('Da lunedì alle 9.'), findsOneWidget);
    // Il nome del canale compare sulla card.
    expect(find.textContaining('Canale 1'), findsOneWidget);
  });

  testWidgets('errore: messaggio e Riprova', (tester) async {
    final news = FakeNewsRepository(news: [makeNews(1, title: 'Orari estivi')])
      ..listError = const NetworkFailure();
    await openNewsTab(tester, news);

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    news.listError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Orari estivi'), findsOneWidget);
  });

  testWidgets('scorrendo in fondo carica la pagina successiva', (tester) async {
    final news = FakeNewsRepository(
      news: [for (var i = 1; i <= 25; i++) makeNews(i)],
    );
    await openNewsTab(tester, news);

    expect(news.listCalls.map((c) => c.offset), [0]);
    expect(news.listCalls.first.limit, 20);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pumpAndSettle();

    expect(news.listCalls.map((c) => c.offset), [0, 20]);
    expect(find.text('News 25'), findsOneWidget);
  });

  testWidgets('tirare giù ricarica le news', (tester) async {
    final news = FakeNewsRepository(news: [makeNews(1)]);
    await openNewsTab(tester, news);
    expect(news.listCalls, hasLength(1));

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      800,
    );
    await tester.pumpAndSettle();

    expect(news.listCalls, hasLength(2));
  });
}
