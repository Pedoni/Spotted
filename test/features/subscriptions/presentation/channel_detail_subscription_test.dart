import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Future<FakeSubscriptionsRepository> openDetail(
    WidgetTester tester, {
    Set<String>? subscribed,
    Map<String, int>? counts,
  }) async {
    final channel = makeChannel(1, name: 'Spotted Pisa');
    final subscriptions = FakeSubscriptionsRepository(
      channels: [channel],
      subscribedIds: subscribed,
      counts: counts ?? {'c1': 3},
    );
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      subscriptions: subscriptions,
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    return subscriptions;
  }

  testWidgets('mostra gli iscritti e il pulsante Segui', (tester) async {
    await openDetail(tester);

    expect(find.byTooltip('3 iscritti'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // Non segui ancora: pulsante pieno con la persona e il più.
    expect(find.text('Segui'), findsOneWidget);
    expect(
      find.widgetWithIcon(FilledButton, Icons.person_add_rounded),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.person_remove_rounded), findsNothing);
  });

  testWidgets('già iscritto: pulsante con il bordo, la persona e il meno', (
    tester,
  ) async {
    await openDetail(tester, subscribed: {'c1'});

    expect(
      find.widgetWithIcon(OutlinedButton, Icons.person_remove_rounded),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.person_add_rounded), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    // Il testo è sempre "Segui"; per esteso si legge nel suggerimento.
    expect(find.text('Segui'), findsOneWidget);
    expect(find.byTooltip('Smetti di seguire'), findsOneWidget);
  });

  testWidgets('plurale: nessun iscritto e un iscritto', (tester) async {
    await openDetail(tester, counts: {'c1': 0});
    expect(find.byTooltip('Nessun iscritto'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('seguendo, il pulsante cambia e il conteggio sale', (
    tester,
  ) async {
    final subscriptions = await openDetail(tester, counts: {'c1': 1});
    expect(find.byTooltip('1 iscritto'), findsOneWidget);

    await tester.tap(find.text('Segui'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_remove_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_add_rounded), findsNothing);
    expect(find.byTooltip('2 iscritti'), findsOneWidget);
    expect(subscriptions.calls, ['subscribe:c1']);
  });

  testWidgets('già iscritto: Smetti di seguire', (tester) async {
    final subscriptions = await openDetail(tester, subscribed: {'c1'});
    expect(find.byIcon(Icons.person_remove_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_remove_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_remove_rounded), findsNothing);
    expect(find.byTooltip('2 iscritti'), findsOneWidget);
    expect(subscriptions.calls, ['unsubscribe:c1']);
  });

  testWidgets('errore: messaggio e stato ripristinato', (tester) async {
    final subscriptions = await openDetail(tester);
    subscriptions.toggleError = const NetworkFailure();

    await tester.tap(find.text('Segui'));
    await tester.pumpAndSettle();

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
    expect(find.byIcon(Icons.person_add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_remove_rounded), findsNothing);
    expect(find.byTooltip('3 iscritti'), findsOneWidget);
  });
}
