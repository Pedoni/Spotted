import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';
import 'package:spotted/features/spots/presentation/widgets/spots_filter_bar.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  late FakeSpotsRepository spots;

  FakeSpotsRepository makeSpots() => FakeSpotsRepository(
    spots: [
      makeSpot(
        1,
        title: 'Ombrello perso',
        content: 'Lasciato in aula B dopo la lezione',
      ),
      makeSpot(2, title: 'Perché non rispondi?', content: 'Ti ho scritto ieri'),
      makeSpot(3, title: 'Sconto libri', content: 'Fino al 100% sui testi'),
      makeSpot(
        4,
        title: 'Cercasi appunti',
        content: 'Qualcuno ha un ombrello?',
      ),
    ],
  );

  Future<void> openChannel(WidgetTester tester) async {
    spots = makeSpots();
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots: spots,
      // L'intestazione del canale è alta: serve uno schermo alto.
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
  }

  /// Il campo di ricerca: sempre visibile in cima alla scheda Spots.
  final searchField = find.descendant(
    of: find.byType(SpotsFilterBar),
    matching: find.byType(TextField),
  );

  /// Scrive [text] e aspetta che la ricerca (con la sua attesa) finisca.
  Future<void> searchFor(WidgetTester tester, String text) async {
    await tester.enterText(searchField, text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  /// I titoli degli spot che si vedono, in ordine.
  List<String> shownSpots(WidgetTester tester) => tester
      .widgetList<SpotCard>(find.byType(SpotCard))
      .map((card) => card.spot.title)
      .toList();

  /// Le parti evidenziate del testo [full] che si vede nella pagina.
  List<String> highlightedIn(WidgetTester tester, String full) {
    final text = tester.widget<Text>(find.text(full));
    final pieces = <String>[];
    text.textSpan?.visitChildren((span) {
      if (span is TextSpan && span.style?.backgroundColor != null) {
        pieces.add(span.text!);
      }
      return true;
    });
    return pieces;
  }

  group('la barra di ricerca', () {
    testWidgets('è sempre visibile, senza dover aprire niente', (
      tester,
    ) async {
      await openChannel(tester);

      expect(searchField, findsOneWidget);
      expect(find.text('Cerca negli spot'), findsOneWidget); // il suggerimento
      // Non c'è più la lente nella barra dell'app.
      expect(find.byTooltip('Cerca negli spot'), findsNothing);
      // E il canale resta com'è: intestazione, spot e pulsante Pubblica.
      expect(find.text('Pubblica uno spot'), findsOneWidget);
      expect(shownSpots(tester), contains('Sconto libri'));
    });

    testWidgets('sta sotto la barra delle schede, non sopra', (tester) async {
      await openChannel(tester);

      expect(
        tester.getRect(searchField).top,
        greaterThan(tester.getRect(find.byType(TabBar)).bottom),
      );
    });

    testWidgets('c è solo nella scheda Spots', (tester) async {
      await openChannel(tester);

      await tester.tap(find.text('News'));
      await tester.pumpAndSettle();
      expect(searchField, findsNothing);

      await tester.tap(find.text('Spots'));
      await tester.pumpAndSettle();
      expect(searchField, findsOneWidget);
    });

    testWidgets('"indietro" lascia il canale (non c è una ricerca aperta)', (
      tester,
    ) async {
      await openChannel(tester);
      await searchFor(tester, 'ombrello');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Pubblica uno spot'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('ricerca', () {
    testWidgets('con una sola lettera non cerca: restano tutti gli spot', (
      tester,
    ) async {
      await openChannel(tester);
      final before = spots.queries.length;

      await searchFor(tester, 'o');

      expect(spots.queries, hasLength(before));
      expect(shownSpots(tester), hasLength(4));
      // Ricorda che serve qualche lettera in più.
      expect(
        find.text('Scrivi almeno 2 lettere per cercare'),
        findsOneWidget,
      );
    });

    testWidgets('cerca nel titolo e nel testo, ovunque', (tester) async {
      await openChannel(tester);

      await searchFor(tester, 'ombrello');

      // Uno ha "ombrello" nel titolo, l'altro nel testo.
      expect(
        shownSpots(tester),
        unorderedEquals(['Ombrello perso', 'Cercasi appunti']),
      );
      expect(spots.queries.last, 'ombrello');
    });

    testWidgets('cerca a metà parola', (tester) async {
      await openChannel(tester);

      await searchFor(tester, 'brell');

      expect(shownSpots(tester), hasLength(2));
    });

    testWidgets('non distingue maiuscole e accenti', (tester) async {
      await openChannel(tester);

      await searchFor(tester, 'PERCHE');

      expect(shownSpots(tester), ['Perché non rispondi?']);
    });

    testWidgets('evidenzia il testo trovato nel titolo e nello spot', (
      tester,
    ) async {
      await openChannel(tester);

      await searchFor(tester, 'ombrello');

      expect(highlightedIn(tester, 'Ombrello perso'), ['Ombrello']);
      expect(
        highlightedIn(tester, 'Qualcuno ha un ombrello?'),
        ['ombrello'],
      );
      expect(
        tester
            .widgetList<SpotCard>(find.byType(SpotCard))
            .every((card) => card.highlight == 'ombrello'),
        isTrue,
      );
    });

    testWidgets('nessun risultato: lo dice e si può azzerare', (tester) async {
      await openChannel(tester);

      await searchFor(tester, 'zzzz');

      expect(find.text('Nessuno spot per «zzzz»'), findsOneWidget);
      expect(find.byType(SpotCard), findsNothing);

      await tester.tap(find.text('Azzera i filtri'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(searchField).controller!.text, isEmpty);
      expect(shownSpots(tester), hasLength(4));
    });

    testWidgets('i simboli speciali valgono come lettere', (tester) async {
      await openChannel(tester);

      await searchFor(tester, '100%');

      expect(shownSpots(tester), ['Sconto libri']);
      expect(spots.queries.last, '100%');
    });

    testWidgets('gli spazi ai bordi non contano', (tester) async {
      await openChannel(tester);

      await searchFor(tester, '  ombrello  ');

      expect(spots.queries.last, 'ombrello');
      expect(shownSpots(tester), hasLength(2));
    });

    testWidgets('aspetta che si smetta di scrivere prima di cercare', (
      tester,
    ) async {
      await openChannel(tester);
      final before = spots.queries.length;

      await tester.enterText(searchField, 'om');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(searchField, 'omb');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(searchField, 'ombr');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Una sola richiesta, per il testo finale.
      expect(spots.queries.skip(before), ['ombr']);
    });

    testWidgets('cambiando il testo cambiano i risultati', (tester) async {
      await openChannel(tester);
      await searchFor(tester, 'ombrello');
      expect(shownSpots(tester), hasLength(2));

      await searchFor(tester, 'sconto');

      expect(shownSpots(tester), ['Sconto libri']);
    });

    testWidgets('toccando un risultato si apre lo spot', (tester) async {
      await openChannel(tester);
      await searchFor(tester, 'sconto');

      await tester.tap(find.byType(SpotCard));
      await tester.pumpAndSettle();

      expect(find.text('Spot'), findsOneWidget); // il titolo della pagina
    });

    testWidgets('errore nella ricerca: messaggio e Riprova', (tester) async {
      await openChannel(tester);
      spots.listError = const NetworkFailure();

      await searchFor(tester, 'ombrello');

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      spots.listError = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(shownSpots(tester), hasLength(2));
    });

    testWidgets('il pulsante Pubblica resta con la ricerca attiva', (
      tester,
    ) async {
      await openChannel(tester);

      await searchFor(tester, 'ombrello');

      expect(find.text('Pubblica uno spot'), findsOneWidget);
    });
  });

  group('cancellare', () {
    testWidgets('la x non c è a campo vuoto', (tester) async {
      await openChannel(tester);

      expect(find.byTooltip('Cancella'), findsNothing);

      await tester.enterText(searchField, 'om');
      await tester.pump();
      expect(find.byTooltip('Cancella'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    });

    testWidgets('la x svuota il campo e tornano tutti gli spot', (
      tester,
    ) async {
      await openChannel(tester);
      await searchFor(tester, 'ombrello');
      expect(shownSpots(tester), hasLength(2));

      await tester.tap(find.byTooltip('Cancella'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(searchField).controller!.text, isEmpty);
      expect(shownSpots(tester), hasLength(4));
      expect(find.byTooltip('Cancella'), findsNothing);
    });

    testWidgets('svuotando a mano gli spot tornano subito', (tester) async {
      await openChannel(tester);
      await searchFor(tester, 'ombrello');

      await tester.enterText(searchField, '');
      // Nessuna attesa di 300 ms: la richiesta senza testo parte subito.
      await tester.pump();
      expect(spots.queries.last, isNull);
      await tester.pumpAndSettle();

      expect(shownSpots(tester), hasLength(4));
    });
  });
}
