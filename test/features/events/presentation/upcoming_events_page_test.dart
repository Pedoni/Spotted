import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

import '../../../helpers/fake_events.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  /// Home → freccia di "Prossimi eventi".
  Future<void> openPage(
    WidgetTester tester,
    FakeEventsRepository events,
  ) async {
    await pumpApp(tester, events: events, screenSize: tallScreen);
    await tester.tap(find.byTooltip('Visualizza tutti'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra tutti gli eventi con il canale, dal più vicino', (
    tester,
  ) async {
    final events = FakeEventsRepository()
      ..followed = [
        makeEvent(1, title: 'Aperitivo', channelName: 'Spotted Pisa'),
        makeEvent(2, title: 'Concerto', channelName: 'Altro canale'),
      ];
    await openPage(tester, events);

    expect(find.text('Aperitivo'), findsOneWidget);
    expect(find.text('Concerto'), findsOneWidget);
    expect(find.text('Spotted Pisa'), findsOneWidget);
    expect(find.text('Altro canale'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Aperitivo')).dy,
      lessThan(tester.getTopLeft(find.text('Concerto')).dy),
    );
  });

  testWidgets('scorrendo in fondo carica la pagina successiva', (tester) async {
    final events = FakeEventsRepository()
      ..followed = [for (var i = 1; i <= 25; i++) makeEvent(i)];
    await openPage(tester, events);

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -6000));
      await tester.pumpAndSettle();
    }

    expect(
      events.followedCalls.map((c) => c.offset),
      containsAllInOrder([0, 20]),
    );
    expect(find.text('Evento 25'), findsOneWidget);
  });

  testWidgets('toccare un evento lo apre', (tester) async {
    final event = makeEvent(1, title: 'Aperitivo');
    final events = FakeEventsRepository(events: [event])..followed = [event];
    await openPage(tester, events);

    await tester.tap(find.text('Aperitivo'));
    await tester.pumpAndSettle();

    expect(find.text("Descrizione dell'evento 1"), findsOneWidget);
  });

  testWidgets('toccare il nome del canale apre il canale', (tester) async {
    final channel = makeChannel(1, name: 'Spotted Pisa');
    final events = FakeEventsRepository()
      ..followed = [makeEvent(1, channelName: 'Spotted Pisa')];
    await pumpApp(
      tester,
      events: events,
      channels: FakeChannelsRepository(channels: [channel]),
      screenSize: tallScreen,
    );
    await tester.tap(find.byTooltip('Visualizza tutti'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Tab, 'Eventi'), findsOneWidget);
  });

  testWidgets('errore: messaggio e Riprova', (tester) async {
    final events = FakeEventsRepository()..followed = [makeEvent(1)];
    await openPage(tester, events);
    events
      ..followedError = const NetworkFailure()
      ..followed = [makeEvent(1, title: 'Aperitivo')];

    await tester.fling(find.byType(ListView), const Offset(0, 800), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    events.followedError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Aperitivo'), findsOneWidget);
  });
}
