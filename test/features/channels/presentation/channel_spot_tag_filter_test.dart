import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';
import 'package:spotted/features/spots/presentation/widgets/spots_filter_bar.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/fake_tags.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  late FakeSpotsRepository spots;
  late FakeTagsRepository tags;

  FakeSpotsRepository makeSpots() => FakeSpotsRepository(
    spots: [
      makeSpot(1, title: 'Ombrello perso', tags: ['perso', 'crush']),
      makeSpot(2, title: 'Chi è il ragazzo?', tags: ['crush']),
      makeSpot(3, title: 'Appunti di analisi', tags: ['esami']),
      makeSpot(4, title: 'Spot senza tag'),
    ],
  );

  Future<void> openChannel(WidgetTester tester) async {
    spots = makeSpots();
    tags = FakeTagsRepository();
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots: spots,
      tags: tags,
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
  }

  final filterButton = find.byTooltip('Filtra per tag');
  final sheetChip = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.byType(FilterChip),
  );
  final applyButton = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.widgetWithText(FilledButton, 'Applica'),
  );

  /// Gli spot che si vedono, in ordine.
  List<String> shownSpots(WidgetTester tester) => tester
      .widgetList<SpotCard>(find.byType(SpotCard))
      .map((card) => card.spot.title)
      .toList();

  /// Apre il foglio, sceglie i tag con [labels] e applica.
  Future<void> filterBy(WidgetTester tester, List<String> labels) async {
    await tester.tap(filterButton);
    await tester.pumpAndSettle();
    for (final label in labels) {
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(FilterChip, label),
        ),
      );
      await tester.pump();
    }
    await tester.tap(applyButton);
    await tester.pumpAndSettle();
  }

  Finder activeChip(String label) => find.widgetWithText(InputChip, label);

  group('il foglio dei tag', () {
    testWidgets('mostra i tag del canale per categoria, senza limite', (
      tester,
    ) async {
      await openChannel(tester);

      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      expect(find.text('Filtra per tag'), findsWidgets);
      expect(
        find.text('Mostra gli spot che hanno almeno uno di questi tag.'),
        findsOneWidget,
      );
      expect(sheetChip, findsNWidgets(fakeTags.length));
      expect(find.text('Generici'), findsOneWidget);
      expect(tags.channelCalls, ['c1']);

      // Tutti i tag si possono scegliere insieme (non c'è il tetto di 3).
      for (final tag in fakeTags) {
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.widgetWithText(FilterChip, tag.label),
          ),
        );
        await tester.pump();
      }
      expect(
        tester.widgetList<FilterChip>(sheetChip).every((chip) => chip.selected),
        isTrue,
      );
    });

    testWidgets('chiuderlo senza applicare non cambia niente', (tester) async {
      await openChannel(tester);
      final before = spots.tagFilters.length;

      await tester.tap(filterButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Crush'));
      await tester.pump();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(spots.tagFilters, hasLength(before));
      expect(shownSpots(tester), hasLength(4));
      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('errore nel caricare i tag: Riprova', (tester) async {
      await openChannel(tester);
      tags.error = const NetworkFailure();

      await tester.tap(filterButton);
      await tester.pumpAndSettle();
      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      tags.error = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(sheetChip, findsNWidgets(fakeTags.length));
    });
  });

  group('filtrare', () {
    testWidgets('un tag: solo gli spot che lo hanno', (tester) async {
      await openChannel(tester);

      await filterBy(tester, ['Crush']);

      expect(shownSpots(tester), ['Ombrello perso', 'Chi è il ragazzo?']);
      expect(spots.tagFilters.last, ['crush']);
    });

    testWidgets('più tag: gli spot che ne hanno almeno uno', (tester) async {
      await openChannel(tester);

      await filterBy(tester, ['Crush', 'Esami']);

      expect(
        shownSpots(tester),
        ['Ombrello perso', 'Chi è il ragazzo?', 'Appunti di analisi'],
      );
      expect(spots.tagFilters.last, unorderedEquals(['crush', 'esami']));
    });

    testWidgets('i tag scelti si vedono come chip, col numero sul pulsante', (
      tester,
    ) async {
      await openChannel(tester);
      expect(find.byType(InputChip), findsNothing);

      await filterBy(tester, ['Crush', 'Esami']);

      expect(activeChip('Crush'), findsOneWidget);
      expect(activeChip('Esami'), findsOneWidget);
      final badge = tester.widget<Badge>(
        find.descendant(
          of: find.byType(SpotsFilterBar),
          matching: find.byType(Badge),
        ),
      );
      expect(badge.isLabelVisible, isTrue);
      expect(
        find.descendant(
          of: find.byType(SpotsFilterBar),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('la x di un chip toglie quel tag', (tester) async {
      await openChannel(tester);
      await filterBy(tester, ['Crush', 'Esami']);

      await tester.tap(
        find.descendant(
          of: activeChip('Crush'),
          matching: find.byType(Icon),
        ),
      );
      await tester.pumpAndSettle();

      expect(activeChip('Crush'), findsNothing);
      expect(activeChip('Esami'), findsOneWidget);
      expect(shownSpots(tester), ['Appunti di analisi']);
      expect(spots.tagFilters.last, ['esami']);
    });

    testWidgets('togliendo l ultimo chip tornano tutti gli spot', (
      tester,
    ) async {
      await openChannel(tester);
      await filterBy(tester, ['Esami']);
      expect(shownSpots(tester), hasLength(1));

      await tester.tap(
        find.descendant(
          of: activeChip('Esami'),
          matching: find.byType(Icon),
        ),
      );
      await tester.pumpAndSettle();

      expect(shownSpots(tester), hasLength(4));
      expect(find.byType(InputChip), findsNothing);
      expect(spots.tagFilters.last, isEmpty);
    });

    testWidgets('Azzera nel foglio toglie tutti i tag', (tester) async {
      await openChannel(tester);
      await filterBy(tester, ['Crush']);

      await tester.tap(filterButton);
      await tester.pumpAndSettle();
      // Il foglio riparte dalla scelta attuale.
      expect(
        tester
            .widget<FilterChip>(
              find.descendant(
                of: find.byType(BottomSheet),
                matching: find.widgetWithText(FilterChip, 'Crush'),
              ),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.text('Azzera'));
      await tester.pumpAndSettle();

      expect(find.byType(InputChip), findsNothing);
      expect(shownSpots(tester), hasLength(4));
    });

    testWidgets('si somma alla ricerca di testo', (tester) async {
      await openChannel(tester);
      await filterBy(tester, ['Crush']);

      await tester.enterText(
        find.descendant(
          of: find.byType(SpotsFilterBar),
          matching: find.byType(TextField),
        ),
        'ombrello',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(shownSpots(tester), ['Ombrello perso']);
      expect(spots.queries.last, 'ombrello');
      expect(spots.tagFilters.last, ['crush']);
    });

    testWidgets('nessuno spot con i tag: lo dice e si può azzerare', (
      tester,
    ) async {
      await openChannel(tester);
      spots.spots = [
        makeSpot(1, title: 'Solo crush', tags: ['crush']),
      ];

      await filterBy(tester, ['Esami']);

      expect(find.text('Nessuno spot con questi tag'), findsOneWidget);
      expect(find.text('Prova a togliere qualche filtro.'), findsOneWidget);

      await tester.tap(find.text('Azzera i filtri'));
      await tester.pumpAndSettle();

      expect(shownSpots(tester), ['Solo crush']);
      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('Azzera i filtri toglie anche il testo cercato', (
      tester,
    ) async {
      await openChannel(tester);
      await filterBy(tester, ['Esami']);
      await tester.enterText(
        find.descendant(
          of: find.byType(SpotsFilterBar),
          matching: find.byType(TextField),
        ),
        'zzzz',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Nessuno spot per «zzzz»'), findsOneWidget);

      await tester.tap(find.text('Azzera i filtri'));
      await tester.pumpAndSettle();

      expect(shownSpots(tester), hasLength(4));
      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('il pulsante Pubblica resta con i tag scelti', (tester) async {
      await openChannel(tester);

      await filterBy(tester, ['Crush']);

      expect(find.text('Pubblica uno spot'), findsOneWidget);
    });

    testWidgets('errore: messaggio e Riprova', (tester) async {
      await openChannel(tester);
      spots.listError = const NetworkFailure();

      await filterBy(tester, ['Crush']);

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      spots.listError = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(shownSpots(tester), hasLength(2));
    });
  });

  testWidgets('senza filtri la richiesta è quella di sempre', (tester) async {
    await openChannel(tester);

    expect(spots.tagFilters.every((t) => t.isEmpty), isTrue);
    expect(spots.queries.every((q) => q == null), isTrue);
  });
}
