import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/widgets/empty_state.dart';

import '../../../helpers/fake_events.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  /// Canali → il canale → scheda Eventi.
  Future<void> openEventsTab(
    WidgetTester tester,
    FakeEventsRepository events, {
    bool owner = false,
  }) async {
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      events: events,
      moderation: FakeModerationRepository(
        ownedChannelIds: owner ? {'c1'} : {},
      ),
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Eventi'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra i prossimi eventi, dal più vicino, con luogo e data', (
    tester,
  ) async {
    await openEventsTab(
      tester,
      FakeEventsRepository(
        events: [
          makeEvent(5, title: 'Concerto', location: 'Piazza Garibaldi'),
          makeEvent(2, title: 'Aperitivo'),
          makeEvent(1, title: 'Già finito', past: true),
          makeEvent(3, channelId: 'altro', title: 'Di un altro canale'),
        ],
      ),
    );

    expect(find.text('Aperitivo'), findsOneWidget);
    expect(find.text('Concerto'), findsOneWidget);
    expect(find.text('Piazza Garibaldi'), findsOneWidget);
    expect(find.text('Già finito'), findsNothing);
    expect(find.text('Di un altro canale'), findsNothing);
    // L'ordine è dal più vicino.
    expect(
      tester.getTopLeft(find.text('Aperitivo')).dy,
      lessThan(tester.getTopLeft(find.text('Concerto')).dy),
    );
  });

  testWidgets('la data compare in evidenza, con giorno e mese', (
    tester,
  ) async {
    await openEventsTab(
      tester,
      FakeEventsRepository(
        events: [makeEvent(1, startsAt: DateTime(2031, 3, 14, 18, 30))],
      ),
    );

    expect(find.text('14'), findsOneWidget);
    expect(find.text('MAR'), findsOneWidget);
    // Per esteso, con l'ora a 24 ore.
    expect(find.textContaining('18:30'), findsOneWidget);
  });

  testWidgets('"Passati" mostra gli eventi finiti, dal più recente', (
    tester,
  ) async {
    await openEventsTab(
      tester,
      FakeEventsRepository(
        events: [
          makeEvent(1, title: 'In arrivo'),
          makeEvent(2, title: 'Ieri', past: true),
          makeEvent(9, title: 'Mesi fa', past: true),
        ],
      ),
    );

    await tester.tap(find.text('Passati'));
    await tester.pumpAndSettle();

    expect(find.text('Ieri'), findsOneWidget);
    expect(find.text('Mesi fa'), findsOneWidget);
    expect(find.text('In arrivo'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Ieri')).dy,
      lessThan(tester.getTopLeft(find.text('Mesi fa')).dy),
    );

    await tester.tap(find.text('Prossimi'));
    await tester.pumpAndSettle();
    expect(find.text('In arrivo'), findsOneWidget);
    expect(find.text('Ieri'), findsNothing);
  });

  testWidgets('un evento senza fine resta tra i prossimi per 3 ore', (
    tester,
  ) async {
    await openEventsTab(
      tester,
      FakeEventsRepository(
        events: [
          makeEvent(
            1,
            title: "Iniziato da un'ora",
            startsAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          makeEvent(
            2,
            title: 'Iniziato da cinque ore',
            startsAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ],
      ),
    );

    expect(find.text("Iniziato da un'ora"), findsOneWidget);
    expect(find.text('Iniziato da cinque ore'), findsNothing);
  });

  testWidgets('senza eventi: segnaposto al centro, senza pulsanti', (
    tester,
  ) async {
    await openEventsTab(tester, FakeEventsRepository());

    expect(find.text('Nessun evento in programma'), findsOneWidget);
    expect(
      find.text('Qui compariranno gli eventi del canale.'),
      findsOneWidget,
    );
    expect(find.byType(EmptyState), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(EmptyState),
        matching: find.byType(FilledButton),
      ),
      findsNothing,
    );
  });

  testWidgets('senza eventi passati: lo dice', (tester) async {
    await openEventsTab(tester, FakeEventsRepository());

    await tester.tap(find.text('Passati'));
    await tester.pumpAndSettle();

    expect(find.text('Nessun evento passato'), findsOneWidget);
    expect(
      find.text('Gli eventi già svolti compariranno qui.'),
      findsOneWidget,
    );
  });

  testWidgets('il pulsante Pubblica un evento è solo del proprietario', (
    tester,
  ) async {
    await openEventsTab(tester, FakeEventsRepository(events: [makeEvent(1)]));
    expect(find.text('Pubblica un evento'), findsNothing);
  });

  testWidgets('il proprietario vede il pulsante solo nella scheda Eventi', (
    tester,
  ) async {
    await openEventsTab(
      tester,
      FakeEventsRepository(events: [makeEvent(1)]),
      owner: true,
    );
    expect(find.text('Pubblica un evento'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Spots'));
    await tester.pumpAndSettle();
    expect(find.text('Pubblica un evento'), findsNothing);
    expect(find.text('Pubblica uno spot'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'News'));
    await tester.pumpAndSettle();
    expect(find.text('Pubblica un evento'), findsNothing);
    expect(find.text('Pubblica una news'), findsOneWidget);
  });

  testWidgets('toccare un evento apre il dettaglio con la descrizione intera', (
    tester,
  ) async {
    await openEventsTab(
      tester,
      FakeEventsRepository(
        events: [
          makeEvent(
            1,
            title: 'Aperitivo',
            description: 'Un aperitivo per conoscersi.',
          ),
        ],
      ),
    );

    await tester.tap(find.text('Aperitivo'));
    await tester.pumpAndSettle();

    expect(find.text('Evento'), findsOneWidget);
    expect(find.text('Un aperitivo per conoscersi.'), findsOneWidget);
    expect(find.text('Canale 1'), findsOneWidget);
  });

  testWidgets('errore: messaggio e Riprova', (tester) async {
    final events = FakeEventsRepository(
      events: [makeEvent(1, title: 'Aperitivo')],
    )..listError = const NetworkFailure();
    await openEventsTab(tester, events);

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    events.listError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Aperitivo'), findsOneWidget);
  });

  testWidgets('scorrendo in fondo carica la pagina successiva', (tester) async {
    final events = FakeEventsRepository(
      events: [for (var i = 1; i <= 25; i++) makeEvent(i)],
    );
    await openEventsTab(tester, events);

    expect(events.listCalls.first.limit, 20);
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
      await tester.pumpAndSettle();
    }

    expect(events.listCalls.map((c) => c.offset), containsAllInOrder([0, 20]));
    expect(find.text('Evento 25'), findsOneWidget);
  });

  testWidgets('tirare giù ricarica il periodo che si sta guardando', (
    tester,
  ) async {
    final events = FakeEventsRepository(events: [makeEvent(1)]);
    await openEventsTab(tester, events);
    await tester.tap(find.text('Passati'));
    await tester.pumpAndSettle();
    final before = events.listCalls.length;

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      800,
    );
    await tester.pumpAndSettle();

    expect(events.listCalls.length, before + 1);
    expect(events.listCalls.last.when.name, 'past');
  });
}
