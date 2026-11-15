import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/spots/presentation/widgets/my_spots_carousel.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  testWidgets('senza spot propri: messaggio che invita a pubblicare', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('I miei spot'), findsOneWidget);
    expect(find.text('Non hai ancora pubblicato spot'), findsOneWidget);
    expect(find.textContaining('Premi Pubblica'), findsOneWidget);
    // Non c'è niente da vedere: niente freccia.
    expect(find.byTooltip('Visualizza tutti'), findsNothing);
  });

  testWidgets('con spot propri mostra il carosello e non il feed dei canali', (
    tester,
  ) async {
    final spots = FakeSpotsRepository(
      mine: [makeMySpot(1)],
      followed: [makeMySpot(2)],
    );
    await pumpApp(tester, spots: spots);

    expect(find.byType(MySpotCard), findsOneWidget);
    expect(find.text('Spot 1'), findsOneWidget);
    expect(find.text('Spot 2'), findsNothing);
    expect(spots.followedCalls, isEmpty);
  });

  testWidgets('tirando giù si ricaricano i miei spot', (tester) async {
    final spots = FakeSpotsRepository(mine: [makeMySpot(1)]);
    await pumpApp(tester, spots: spots);
    expect(spots.mineCalls, hasLength(1));

    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(spots.mineCalls, hasLength(2));
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
