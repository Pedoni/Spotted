import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';

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
    );
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
  }

  final searchButton = find.byTooltip('Cerca negli spot');
  final searchField = find.descendant(
    of: find.byType(AppBar),
    matching: find.byType(TextField),
  );

  Future<void> openSearch(WidgetTester tester) async {
    await tester.tap(searchButton);
    await tester.pumpAndSettle();
  }

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

  group('apertura e chiusura', () {
    testWidgets('la lente c è, il pulsante Pubblica anche', (tester) async {
      await openChannel(tester);

      expect(searchButton, findsOneWidget);
      expect(find.text('Pubblica uno spot'), findsOneWidget);
    });

    testWidgets(
      'aprendo la ricerca: campo, suggerimento, niente intestazione',
      (
        tester,
      ) async {
        await openChannel(tester);

        await openSearch(tester);

        expect(searchField, findsOneWidget);
        expect(
          find.text('Cerca negli spot'),
          findsOneWidget,
        ); // il suggerimento
        expect(
          find.text('Scrivi almeno 2 lettere per cercare'),
          findsOneWidget,
        );
        // L'intestazione del canale e il pulsante spariscono.
        expect(find.text('Pubblica uno spot'), findsNothing);
        expect(find.byType(SpotCard), findsNothing);
        expect(find.byTooltip('Chiudi la ricerca'), findsOneWidget);
      },
    );

    testWidgets('il campo è già attivo: si può scrivere subito', (
      tester,
    ) async {
      await openChannel(tester);
      await openSearch(tester);

      final field = tester.widget<TextField>(searchField);
      expect(field.autofocus, isTrue);
    });

    testWidgets('la freccia chiude la ricerca e torna il canale', (
      tester,
    ) async {
      await openChannel(tester);
      await openSearch(tester);
      await searchFor(tester, 'ombrello');
      expect(shownSpots(tester), isNotEmpty);

      await tester.tap(find.byTooltip('Chiudi la ricerca'));
      await tester.pumpAndSettle();

      expect(searchField, findsNothing);
      expect(find.text('Pubblica uno spot'), findsOneWidget);
      // Tornano gli spot del canale (la lista mostra quelli che entrano).
      expect(shownSpots(tester), contains('Perché non rispondi?'));
      expect(shownSpots(tester), contains('Sconto libri'));
      expect(spots.queries.last, isNull);
    });

    testWidgets('"indietro" del telefono chiude la ricerca, non il canale', (
      tester,
    ) async {
      await openChannel(tester);
      await openSearch(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(searchField, findsNothing);
      // Siamo ancora nel canale.
      expect(find.text('Pubblica uno spot'), findsOneWidget);
      expect(find.text('Spotted Pisa'), findsWidgets);
    });

    testWidgets('"indietro" a ricerca chiusa lascia il canale', (tester) async {
      await openChannel(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Pubblica uno spot'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('riaprendo la ricerca si riparte da capo', (tester) async {
      await openChannel(tester);
      await openSearch(tester);
      await searchFor(tester, 'ombrello');
      await tester.tap(find.byTooltip('Chiudi la ricerca'));
      await tester.pumpAndSettle();

      await openSearch(tester);

      expect(tester.widget<TextField>(searchField).controller!.text, isEmpty);
      expect(
        find.text('Scrivi almeno 2 lettere per cercare'),
        findsOneWidget,
      );
      expect(find.byType(SpotCard), findsNothing);
    });
  });

  group('ricerca', () {
    testWidgets('con una sola lettera non cerca', (tester) async {
      await openChannel(tester);
      await openSearch(tester);
      final before = spots.queries.length;

      await searchFor(tester, 'o');

      expect(find.byType(SpotCard), findsNothing);
      expect(spots.queries, hasLength(before));
      expect(
        find.text('Scrivi almeno 2 lettere per cercare'),
        findsOneWidget,
      );
    });

    testWidgets('cerca nel titolo e nel testo, ovunque', (tester) async {
      await openChannel(tester);
      await openSearch(tester);

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
      await openSearch(tester);

      await searchFor(tester, 'brell');

      expect(shownSpots(tester), hasLength(2));
    });

    testWidgets('non distingue maiuscole e accenti', (tester) async {
      await openChannel(tester);
      await openSearch(tester);

      await searchFor(tester, 'PERCHE');

      expect(shownSpots(tester), ['Perché non rispondi?']);
    });

    testWidgets('evidenzia il testo trovato nel titolo e nello spot', (
      tester,
    ) async {
      await openChannel(tester);
      await openSearch(tester);

      await searchFor(tester, 'ombrello');

      // Nel titolo di uno spot e nel testo dell'altro la parte trovata è
      // evidenziata.
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

    testWidgets('nessun risultato: lo dice, con il testo cercato', (
      tester,
    ) async {
      await openChannel(tester);
      await openSearch(tester);

      await searchFor(tester, 'zzzz');

      expect(find.text('Nessuno spot per «zzzz»'), findsOneWidget);
      expect(find.byType(SpotCard), findsNothing);
    });

    testWidgets('i simboli speciali valgono come lettere', (tester) async {
      await openChannel(tester);
      await openSearch(tester);

      await searchFor(tester, '100%');

      expect(shownSpots(tester), ['Sconto libri']);
      expect(spots.queries.last, '100%');
    });

    testWidgets('gli spazi ai bordi non contano', (tester) async {
      await openChannel(tester);
      await openSearch(tester);

      await searchFor(tester, '  ombrello  ');

      expect(spots.queries.last, 'ombrello');
      expect(shownSpots(tester), hasLength(2));
    });

    testWidgets('aspetta che si smetta di scrivere prima di cercare', (
      tester,
    ) async {
      await openChannel(tester);
      await openSearch(tester);
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
      await openSearch(tester);
      await searchFor(tester, 'ombrello');
      expect(shownSpots(tester), hasLength(2));

      await searchFor(tester, 'sconto');

      expect(shownSpots(tester), ['Sconto libri']);
    });

    testWidgets('toccando un risultato si apre lo spot', (tester) async {
      await openChannel(tester);
      await openSearch(tester);
      await searchFor(tester, 'sconto');

      await tester.tap(find.byType(SpotCard));
      await tester.pumpAndSettle();

      expect(find.text('Spot'), findsOneWidget); // il titolo della pagina
    });

    testWidgets('errore nella ricerca: messaggio e Riprova', (tester) async {
      await openChannel(tester);
      await openSearch(tester);
      spots.listError = const NetworkFailure();

      await searchFor(tester, 'ombrello');

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      spots.listError = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(shownSpots(tester), hasLength(2));
    });
  });

  group('cancellare', () {
    testWidgets('la x non c è a campo vuoto', (tester) async {
      await openChannel(tester);
      await openSearch(tester);

      expect(find.byTooltip('Cancella'), findsNothing);

      await tester.enterText(searchField, 'om');
      await tester.pump();
      expect(find.byTooltip('Cancella'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    });

    testWidgets('la x svuota il campo e toglie i risultati', (tester) async {
      await openChannel(tester);
      await openSearch(tester);
      await searchFor(tester, 'ombrello');
      expect(shownSpots(tester), isNotEmpty);

      await tester.tap(find.byTooltip('Cancella'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(searchField).controller!.text, isEmpty);
      expect(find.byType(SpotCard), findsNothing);
      expect(
        find.text('Scrivi almeno 2 lettere per cercare'),
        findsOneWidget,
      );
      expect(find.byTooltip('Cancella'), findsNothing);
    });

    testWidgets('svuotando a mano i risultati spariscono subito', (
      tester,
    ) async {
      await openChannel(tester);
      await openSearch(tester);
      await searchFor(tester, 'ombrello');

      await tester.enterText(searchField, '');
      await tester.pump();

      // Senza aspettare: non c'è attesa per togliere i risultati.
      expect(find.byType(SpotCard), findsNothing);
    });
  });
}
