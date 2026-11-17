import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';

import '../../../helpers/fake_events.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  late FakeEventsRepository events;

  /// Canali → il canale → scheda Eventi.
  Future<void> openEventsTab(
    WidgetTester tester, {
    List<ChannelEvent> seed = const [],
    bool owner = true,
  }) async {
    events = FakeEventsRepository(events: seed);
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

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text('Pubblica un evento'));
    await tester.pumpAndSettle();
  }

  /// Sceglie data e ora di un campo con i selettori, accettando i valori
  /// proposti.
  Future<void> pickDateTime(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    // Selettore della data, poi quello dell'ora.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> fillRequired(WidgetTester tester) async {
    await tester.enterText(field('Titolo'), '  Aperitivo  ');
    await tester.enterText(field('Descrizione'), 'Per conoscersi');
  }

  Future<void> tapSubmit(WidgetTester tester, String label) async {
    final button = find.widgetWithText(FilledButton, label);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('pubblicazione', () {
    testWidgets('il form avvisa che l evento è pubblico e a nome del canale', (
      tester,
    ) async {
      await openEventsTab(tester);
      await openForm(tester);

      expect(find.text('Nuovo evento'), findsOneWidget);
      expect(find.text('Spotted Pisa'), findsWidgets);
      expect(
        find.text("L'evento è pubblico e compare a nome del canale."),
        findsOneWidget,
      );
      expect(field('Luogo (facoltativo)'), findsOneWidget);
      expect(find.text('Fine (facoltativa)'), findsOneWidget);
    });

    testWidgets('titolo, descrizione e inizio sono obbligatori', (
      tester,
    ) async {
      await openEventsTab(tester);
      await openForm(tester);

      await tapSubmit(tester, 'Pubblica');

      expect(find.text('Campo obbligatorio'), findsNWidgets(3));
      expect(events.createCalls, isEmpty);
    });

    testWidgets('pubblica l evento con data e luogo e lo mostra in lista', (
      tester,
    ) async {
      await openEventsTab(tester);
      await openForm(tester);

      await fillRequired(tester);
      await tester.enterText(field('Luogo (facoltativo)'), ' Aula magna ');
      await pickDateTime(tester, 'Inizio');
      await tapSubmit(tester, 'Pubblica');

      final call = events.createCalls.single;
      expect(call['channelId'], 'c1');
      expect(call['title'], 'Aperitivo');
      expect(call['description'], 'Per conoscersi');
      expect(call['location'], 'Aula magna');
      // Domani alle 18, proposto dal selettore: nel futuro.
      final starts = call['startsAt']! as DateTime;
      expect(starts.isAfter(DateTime.now()), isTrue);
      expect(starts.hour, 18);
      expect(starts.minute, 0);
      expect(call['endsAt'], isNull);
      expect(find.text('Evento pubblicato'), findsOneWidget);
      expect(find.text('Nuovo evento'), findsNothing);
      expect(find.text('Aperitivo'), findsOneWidget);
    });

    testWidgets('senza luogo manda nessun luogo', (tester) async {
      await openEventsTab(tester);
      await openForm(tester);
      await fillRequired(tester);
      await pickDateTime(tester, 'Inizio');

      await tapSubmit(tester, 'Pubblica');

      expect(events.createCalls.single['location'], isNull);
    });

    testWidgets('la fine si sceglie, si mostra e si può togliere', (
      tester,
    ) async {
      await openEventsTab(tester);
      await openForm(tester);
      await fillRequired(tester);
      await pickDateTime(tester, 'Inizio');

      await pickDateTime(tester, 'Fine (facoltativa)');
      expect(find.byTooltip('Togli la fine'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Togli la fine'));
      await tester.tap(find.byTooltip('Togli la fine'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Togli la fine'), findsNothing);

      await tapSubmit(tester, 'Pubblica');
      expect(events.createCalls.single['endsAt'], isNull);
    });

    testWidgets('con la fine la manda insieme all inizio', (tester) async {
      await openEventsTab(tester);
      await openForm(tester);
      await fillRequired(tester);
      await pickDateTime(tester, 'Inizio');
      await pickDateTime(tester, 'Fine (facoltativa)');

      await tapSubmit(tester, 'Pubblica');

      final call = events.createCalls.single;
      final starts = call['startsAt']! as DateTime;
      final ends = call['endsAt']! as DateTime;
      expect(ends.isBefore(starts), isFalse);
    });

    testWidgets('errore: resta nel form, mostra il messaggio e si può '
        'riprovare', (tester) async {
      await openEventsTab(tester);
      await openForm(tester);
      await fillRequired(tester);
      await pickDateTime(tester, 'Inizio');
      events.createError = const PermissionFailure();

      await tapSubmit(tester, 'Pubblica');

      expect(find.text('Nuovo evento'), findsOneWidget);
      expect(find.text('Evento pubblicato'), findsNothing);
      expect(find.textContaining('permess'), findsOneWidget);

      events.createError = null;
      await tapSubmit(tester, 'Pubblica');

      expect(find.text('Evento pubblicato'), findsOneWidget);
      expect(events.createCalls, hasLength(2));
    });
  });

  group('dettaglio', () {
    testWidgets('chi non è proprietario non vede il menu', (tester) async {
      await openEventsTab(tester, seed: [makeEvent(1)], owner: false);
      await tester.tap(find.text('Evento 1'));
      await tester.pumpAndSettle();

      expect(find.text("Descrizione dell'evento 1"), findsOneWidget);
      expect(find.byTooltip('Altre azioni'), findsNothing);
    });

    testWidgets('il proprietario può modificare ed eliminare', (tester) async {
      await openEventsTab(tester, seed: [makeEvent(1)]);
      await tester.tap(find.text('Evento 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();

      expect(find.text('Modifica evento'), findsOneWidget);
      expect(find.text('Elimina evento'), findsOneWidget);
    });

    testWidgets('mostra inizio e fine insieme quando c è la fine', (
      tester,
    ) async {
      await openEventsTab(
        tester,
        seed: [
          makeEvent(
            1,
            startsAt: DateTime(2031, 3, 14, 18, 30),
            endsAt: DateTime(2031, 3, 14, 20),
          ),
        ],
      );
      await tester.tap(find.text('Evento 1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('18:30 – 20:00'), findsOneWidget);
    });

    testWidgets('evento che non esiste più: errore con Riprova', (
      tester,
    ) async {
      await openEventsTab(tester, seed: [makeEvent(1)]);
      events.detailError = const NotFoundFailure();
      await tester.tap(find.text('Evento 1'));
      await tester.pumpAndSettle();

      expect(find.text('Riprova'), findsOneWidget);
      expect(find.byTooltip('Altre azioni'), findsNothing);
    });
  });

  group('modifica', () {
    Future<void> openEdit(WidgetTester tester) async {
      await tester.tap(find.text('Evento 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifica evento'));
      await tester.pumpAndSettle();
    }

    testWidgets('il modulo parte dai valori dell evento', (tester) async {
      await openEventsTab(
        tester,
        seed: [
          makeEvent(
            1,
            location: 'Aula magna',
            startsAt: DateTime(2031, 3, 14, 18, 30),
            endsAt: DateTime(2031, 3, 14, 20),
          ),
        ],
      );
      await openEdit(tester);

      expect(find.text('Modifica evento'), findsOneWidget);
      expect(find.text('Evento 1'), findsOneWidget);
      expect(find.text("Descrizione dell'evento 1"), findsOneWidget);
      expect(find.text('Aula magna'), findsOneWidget);
      expect(find.textContaining('18:30'), findsOneWidget);
      expect(find.textContaining('20:00'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Salva'), findsOneWidget);
    });

    testWidgets('salva, torna al dettaglio e mostra i valori nuovi', (
      tester,
    ) async {
      await openEventsTab(tester, seed: [makeEvent(1)]);
      await openEdit(tester);

      await tester.enterText(field('Titolo'), 'Titolo nuovo');
      await tester.enterText(field('Luogo (facoltativo)'), 'Piazza');
      await tapSubmit(tester, 'Salva');

      final call = events.updateCalls.single;
      expect(call['eventId'], 'e1');
      expect(call['title'], 'Titolo nuovo');
      expect(call['location'], 'Piazza');
      expect(find.text('Evento modificato'), findsOneWidget);
      expect(find.text('Modifica evento'), findsNothing);
      expect(find.text('Titolo nuovo'), findsOneWidget);
      expect(find.text('Piazza'), findsOneWidget);
    });

    testWidgets('si può correggere un evento già finito (inizio nel passato)', (
      tester,
    ) async {
      await openEventsTab(
        tester,
        seed: [
          makeEvent(
            1,
            startsAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
        ],
      );
      // Un evento passato non è nella scheda "Prossimi": si apre dal dettaglio.
      await tester.tap(find.text('Passati'));
      await tester.pumpAndSettle();
      await openEdit(tester);

      await tester.enterText(field('Titolo'), 'Titolo corretto');
      await tapSubmit(tester, 'Salva');

      expect(events.updateCalls.single['title'], 'Titolo corretto');
      expect(find.text('Evento modificato'), findsOneWidget);
    });

    testWidgets(
      'fine prima dell inizio: errore sul campo e niente salvataggio',
      (
        tester,
      ) async {
        await openEventsTab(
          tester,
          seed: [
            makeEvent(
              1,
              startsAt: DateTime(2031, 3, 14, 18, 30),
              endsAt: DateTime(2031, 3, 14, 20),
            ),
          ],
        );
        await openEdit(tester);
        // Si sposta l'inizio dopo la fine.
        await tester.ensureVisible(find.text('Inizio'));
        await tester.tap(find.text('Inizio'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await tapSubmit(tester, 'Salva');

        expect(
          find.text("La fine non può essere prima dell'inizio"),
          findsOneWidget,
        );
        expect(events.updateCalls, isEmpty);
      },
    );

    testWidgets('errore: resta nel form con il messaggio', (tester) async {
      await openEventsTab(tester, seed: [makeEvent(1)]);
      await openEdit(tester);
      events.updateError = const NetworkFailure();

      await tapSubmit(tester, 'Salva');

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('Evento modificato'), findsNothing);
    });
  });

  group('eliminazione', () {
    Future<void> openDelete(WidgetTester tester, String title) async {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina evento'));
      await tester.pumpAndSettle();
    }

    testWidgets('chiede conferma e, se si annulla, non elimina', (
      tester,
    ) async {
      await openEventsTab(tester, seed: [makeEvent(1)]);
      await openDelete(tester, 'Evento 1');

      expect(find.text("Eliminare l'evento?"), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(events.deleteCalls, isEmpty);
      expect(find.text("Descrizione dell'evento 1"), findsOneWidget);
    });

    testWidgets('elimina, torna alla scheda e l evento non c è più', (
      tester,
    ) async {
      await openEventsTab(tester, seed: [makeEvent(1), makeEvent(2)]);
      await openDelete(tester, 'Evento 1');

      await tester.tap(find.text('Cancella'));
      await tester.pumpAndSettle();

      expect(events.deleteCalls, ['e1']);
      expect(find.text('Evento eliminato'), findsOneWidget);
      expect(find.text('Evento 1'), findsNothing);
      expect(find.text('Evento 2'), findsOneWidget);
    });

    testWidgets('errore: resta nell evento e lo dice', (tester) async {
      await openEventsTab(tester, seed: [makeEvent(1)]);
      await openDelete(tester, 'Evento 1');
      events.deleteError = const NetworkFailure();

      await tester.tap(find.text('Cancella'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text("Descrizione dell'evento 1"), findsOneWidget);
    });
  });
}
