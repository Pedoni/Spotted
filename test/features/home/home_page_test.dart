import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('senza canali seguiti: messaggio e invito a scoprirli', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Non segui ancora nessun canale'), findsOneWidget);

    await tester.tap(find.text('Scopri i canali'));
    await tester.pumpAndSettle();

    expect(find.text('Cerca un canale'), findsOneWidget);
  });

  testWidgets('mostra i canali seguiti e apre il dettaglio', (tester) async {
    final channels = [
      makeChannel(1, name: 'Spotted Pisa', topicId: 't-uni'),
      makeChannel(2, name: 'Spotted Roma'),
    ];
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: channels),
      subscriptions: FakeSubscriptionsRepository(
        channels: channels,
        subscribedIds: {'c1'},
        counts: {'c1': 4},
      ),
    );

    expect(find.text('Spotted Pisa'), findsOneWidget);
    expect(find.text('Università'), findsOneWidget);
    expect(find.text('Spotted Roma'), findsNothing);

    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();

    expect(find.text('4 iscritti'), findsOneWidget);
  });

  testWidgets('seguendo un canale compare nella Home', (tester) async {
    final channel = makeChannel(1, name: 'Spotted Pisa');
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      subscriptions: FakeSubscriptionsRepository(channels: [channel]),
    );
    expect(find.text('Spotted Pisa'), findsNothing);

    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Segui'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Non segui ancora nessun canale'), findsNothing);
    expect(find.text('Spotted Pisa'), findsOneWidget);
  });

  testWidgets('errore: messaggio e Riprova', (tester) async {
    final subscriptions = FakeSubscriptionsRepository()
      ..listError = const NetworkFailure();
    await pumpApp(tester, subscriptions: subscriptions);

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    subscriptions.listError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Non segui ancora nessun canale'), findsOneWidget);
  });
}
