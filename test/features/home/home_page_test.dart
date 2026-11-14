import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/presentation/pages/spot_detail_page.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  testWidgets('senza spot: messaggio e invito a scoprire i canali', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Ancora nessuno spot da mostrare'), findsOneWidget);

    await tester.tap(find.text('Scopri i canali'));
    await tester.pumpAndSettle();

    expect(find.text('Cerca un canale'), findsOneWidget);
  });

  testWidgets('mostra gli spot dei canali seguiti, con il canale', (
    tester,
  ) async {
    final spots = FakeSpotsRepository(
      followed: [makeMySpot(1), makeMySpot(2)],
    );
    await pumpApp(tester, spots: spots);

    expect(find.text('Spot 1'), findsOneWidget);
    expect(find.text('Spot 2'), findsOneWidget);
    expect(find.textContaining('Spotted Pisa'), findsNWidgets(2));
    expect(spots.followedCalls.single, (offset: 0, limit: 20));
  });

  testWidgets('toccando uno spot si apre il dettaglio', (tester) async {
    final spots = FakeSpotsRepository(
      spots: [makeSpot(1)],
      followed: [makeMySpot(1)],
    );
    await pumpApp(tester, spots: spots);

    await tester.tap(find.text('Spot 1'));
    await tester.pumpAndSettle();

    expect(find.byType(SpotDetailPage), findsOneWidget);
  });

  testWidgets('scorrendo carica la pagina successiva', (tester) async {
    final spots = FakeSpotsRepository(
      followed: List.generate(25, (i) => makeMySpot(i + 1)),
    );
    await pumpApp(tester, spots: spots);

    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pumpAndSettle();

    expect(spots.followedCalls.map((call) => call.offset), [0, 20]);
  });

  testWidgets('errore: messaggio e Riprova', (tester) async {
    final spots = FakeSpotsRepository(followed: [makeMySpot(1)])
      ..listError = const NetworkFailure();
    await pumpApp(tester, spots: spots);

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    spots.listError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Spot 1'), findsOneWidget);
  });

  group('Pubblica', () {
    Future<void> openPicker(WidgetTester tester) async {
      await tester.tap(find.text('Pubblica'));
      await tester.pumpAndSettle();
    }

    testWidgets('propone i canali seguiti e apre il form del canale scelto', (
      tester,
    ) async {
      await pumpApp(
        tester,
        channels: FakeChannelsRepository(channels: [channel]),
        subscriptions: FakeSubscriptionsRepository(
          channels: [channel],
          subscribedIds: {'c1'},
        ),
      );

      await openPicker(tester);
      expect(find.text('In quale canale vuoi pubblicare?'), findsOneWidget);
      expect(find.text('Cerca un altro canale'), findsOneWidget);

      await tester.tap(find.text('Spotted Pisa'));
      await tester.pumpAndSettle();

      expect(find.text('Pubblica uno spot'), findsWidgets);
    });

    testWidgets('senza canali seguiti lo dice e resta la ricerca', (
      tester,
    ) async {
      await pumpApp(tester);

      await openPicker(tester);

      expect(find.text('Non segui ancora nessun canale'), findsOneWidget);
      expect(find.text('Cerca un altro canale'), findsOneWidget);
    });

    testWidgets('"Cerca un altro canale" porta alla scheda Canali', (
      tester,
    ) async {
      await pumpApp(tester);

      await openPicker(tester);
      await tester.tap(find.text('Cerca un altro canale'));
      await tester.pumpAndSettle();

      expect(find.text('Cerca un canale'), findsOneWidget);
    });
  });
}
