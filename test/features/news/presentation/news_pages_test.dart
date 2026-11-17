import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';

import '../../../helpers/fake_news.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  late FakeNewsRepository news;

  /// Canali → il canale → scheda News.
  Future<void> openNewsTab(
    WidgetTester tester, {
    List<ChannelNews> seed = const [],
    bool owner = true,
  }) async {
    news = FakeNewsRepository(news: seed);
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

  Future<void> openDetail(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  Future<void> openOwnerMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  group('pubblicazione', () {
    testWidgets('il form avvisa che la news è pubblica e a nome del canale', (
      tester,
    ) async {
      await openNewsTab(tester);
      await tester.tap(find.text('Pubblica una news'));
      await tester.pumpAndSettle();

      expect(find.text('Nuova news'), findsOneWidget);
      expect(find.text('Spotted Pisa'), findsWidgets);
      expect(
        find.text('La news è pubblica e compare a nome del canale.'),
        findsOneWidget,
      );
    });

    testWidgets('titolo e testo sono obbligatori', (tester) async {
      await openNewsTab(tester);
      await tester.tap(find.text('Pubblica una news'));
      await tester.pumpAndSettle();

      await tester.enterText(field('Titolo'), '   ');
      await tester.tap(find.widgetWithText(FilledButton, 'Pubblica'));
      await tester.pump();

      expect(find.text('Campo obbligatorio'), findsNWidgets(2));
      expect(news.createCalls, isEmpty);
    });

    testWidgets('pubblica la news e torna alla scheda con la news in lista', (
      tester,
    ) async {
      await openNewsTab(tester);
      await tester.tap(find.text('Pubblica una news'));
      await tester.pumpAndSettle();

      await tester.enterText(field('Titolo'), '  Orari estivi  ');
      await tester.enterText(field('Testo'), 'Da lunedì alle 9.');
      await tester.tap(find.widgetWithText(FilledButton, 'Pubblica'));
      await tester.pumpAndSettle();

      expect(news.createCalls.single, {
        'channelId': 'c1',
        'title': 'Orari estivi',
        'body': 'Da lunedì alle 9.',
      });
      expect(find.text('News pubblicata'), findsOneWidget);
      expect(find.text('Nuova news'), findsNothing);
      expect(find.text('Orari estivi'), findsOneWidget);
    });

    testWidgets('si può pubblicare anche dal pulsante in basso', (
      tester,
    ) async {
      await openNewsTab(tester, seed: [makeNews(1)]);

      await tester.tap(find.text('Pubblica una news'));
      await tester.pumpAndSettle();

      expect(find.text('Nuova news'), findsOneWidget);
    });

    testWidgets('errore: resta nel form, mostra il messaggio e si può '
        'riprovare', (tester) async {
      await openNewsTab(tester);
      await tester.tap(find.text('Pubblica una news'));
      await tester.pumpAndSettle();
      news.createError = const PermissionFailure();

      await tester.enterText(field('Titolo'), 'Titolo');
      await tester.enterText(field('Testo'), 'Testo');
      await tester.tap(find.widgetWithText(FilledButton, 'Pubblica'));
      await tester.pumpAndSettle();

      expect(find.text('Nuova news'), findsOneWidget);
      expect(find.text('News pubblicata'), findsNothing);
      expect(find.textContaining('permess'), findsOneWidget);

      news.createError = null;
      await tester.tap(find.widgetWithText(FilledButton, 'Pubblica'));
      await tester.pumpAndSettle();

      expect(find.text('News pubblicata'), findsOneWidget);
      expect(news.createCalls, hasLength(2));
    });
  });

  group('dettaglio', () {
    testWidgets('chi non è proprietario non vede il menu', (tester) async {
      await openNewsTab(tester, seed: [makeNews(1)], owner: false);
      await openDetail(tester, 'News 1');

      expect(find.text('Testo della news 1'), findsOneWidget);
      expect(find.byTooltip('Altre azioni'), findsNothing);
    });

    testWidgets('il proprietario può modificare ed eliminare', (tester) async {
      await openNewsTab(tester, seed: [makeNews(1)]);
      await openDetail(tester, 'News 1');

      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();

      expect(find.text('Modifica news'), findsOneWidget);
      expect(find.text('Elimina news'), findsOneWidget);
    });

    testWidgets('news che non esiste più: errore con Riprova', (tester) async {
      await openNewsTab(tester, seed: [makeNews(1)]);
      news.detailError = const NotFoundFailure();
      await openDetail(tester, 'News 1');

      expect(find.text('Riprova'), findsOneWidget);
      expect(find.byTooltip('Altre azioni'), findsNothing);
    });
  });

  group('modifica', () {
    testWidgets('il modulo parte dai valori della news', (tester) async {
      await openNewsTab(tester, seed: [makeNews(1)]);
      await openDetail(tester, 'News 1');
      await openOwnerMenu(tester, 'Modifica news');

      expect(find.text('Modifica news'), findsOneWidget);
      expect(find.text('News 1'), findsOneWidget);
      expect(find.text('Testo della news 1'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Salva'), findsOneWidget);
    });

    testWidgets('salva, torna al dettaglio e mostra i valori nuovi', (
      tester,
    ) async {
      await openNewsTab(tester, seed: [makeNews(1)]);
      await openDetail(tester, 'News 1');
      await openOwnerMenu(tester, 'Modifica news');

      await tester.enterText(field('Titolo'), 'Titolo nuovo');
      await tester.enterText(field('Testo'), 'Testo nuovo');
      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();

      expect(news.updateCalls.single, {
        'newsId': 'n1',
        'title': 'Titolo nuovo',
        'body': 'Testo nuovo',
      });
      expect(find.text('News modificata'), findsOneWidget);
      expect(find.text('Modifica news'), findsNothing);
      expect(find.text('Titolo nuovo'), findsOneWidget);
      expect(find.text('Testo nuovo'), findsOneWidget);
    });

    testWidgets('errore: resta nel form con il messaggio', (tester) async {
      await openNewsTab(tester, seed: [makeNews(1)]);
      await openDetail(tester, 'News 1');
      await openOwnerMenu(tester, 'Modifica news');
      news.updateError = const NetworkFailure();

      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('News modificata'), findsNothing);
    });
  });

  group('eliminazione', () {
    testWidgets('chiede conferma e, se si annulla, non elimina', (
      tester,
    ) async {
      await openNewsTab(tester, seed: [makeNews(1)]);
      await openDetail(tester, 'News 1');
      await openOwnerMenu(tester, 'Elimina news');

      expect(find.text('Eliminare la news?'), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(news.deleteCalls, isEmpty);
      expect(find.text('Testo della news 1'), findsOneWidget);
    });

    testWidgets('elimina, torna alla scheda e la news non c è più', (
      tester,
    ) async {
      await openNewsTab(tester, seed: [makeNews(1), makeNews(2)]);
      await openDetail(tester, 'News 1');
      await openOwnerMenu(tester, 'Elimina news');

      await tester.tap(find.text('Cancella'));
      await tester.pumpAndSettle();

      expect(news.deleteCalls, ['n1']);
      expect(find.text('News eliminata'), findsOneWidget);
      expect(find.text('News 1'), findsNothing);
      expect(find.text('News 2'), findsOneWidget);
    });

    testWidgets('errore: resta nella news e lo dice', (tester) async {
      await openNewsTab(tester, seed: [makeNews(1)]);
      await openDetail(tester, 'News 1');
      await openOwnerMenu(tester, 'Elimina news');
      news.deleteError = const NetworkFailure();

      await tester.tap(find.text('Cancella'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('Testo della news 1'), findsOneWidget);
    });
  });
}
