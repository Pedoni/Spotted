import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';
import 'package:spotted/features/spots/domain/entities/spot_with_channel.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Future<void> openMySpots(
    WidgetTester tester,
    FakeSpotsRepository spots,
  ) async {
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(
        channels: [makeChannel(1, name: 'Spotted Pisa')],
      ),
      spots: spots,
    );
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I miei spot'));
    await tester.pumpAndSettle();
  }

  testWidgets('uno spot nascosto dal proprietario ha l etichetta', (
    tester,
  ) async {
    await openMySpots(
      tester,
      FakeSpotsRepository(
        mine: [
          makeMySpot(1),
          SpotWithChannel(
            spot: makeSpot(2, status: SpotStatus.hidden),
            channelName: 'Spotted Pisa',
            channelSlug: 'canale-1',
          ),
        ],
      ),
    );

    expect(find.text('Spot 1'), findsOneWidget);
    expect(find.text('Spot 2'), findsOneWidget);
    expect(
      find.text('Nascosto dal proprietario del canale'),
      findsOneWidget,
    );
  });

  testWidgets('senza spot: messaggio', (tester) async {
    await openMySpots(tester, FakeSpotsRepository());

    expect(find.text('Non hai ancora pubblicato spot'), findsOneWidget);
  });

  testWidgets('mostra i miei spot con il canale e apre il canale', (
    tester,
  ) async {
    await openMySpots(
      tester,
      FakeSpotsRepository(mine: [makeMySpot(1), makeMySpot(2)]),
    );

    expect(find.text('Spot 1'), findsOneWidget);
    expect(find.text('Spot 2'), findsOneWidget);
    expect(find.textContaining('Spotted Pisa'), findsNWidgets(2));

    await tester.tap(find.textContaining('Spotted Pisa').first);
    await tester.pumpAndSettle();

    expect(find.text('Pubblica uno spot'), findsOneWidget);
  });

  testWidgets('toccando uno spot si apre con i suoi commenti', (tester) async {
    await openMySpots(tester, FakeSpotsRepository(mine: [makeMySpot(1)]));

    await tester.tap(find.text('Spot 1'));
    await tester.pumpAndSettle();

    expect(find.text('Scrivi un commento'), findsOneWidget);
    expect(
      find.text('Ancora nessun commento. Scrivi il primo!'),
      findsOneWidget,
    );
  });

  testWidgets('cancella dopo la conferma', (tester) async {
    final spots = FakeSpotsRepository(mine: [makeMySpot(1), makeMySpot(2)]);
    await openMySpots(tester, spots);

    await tester.tap(find.byTooltip('Cancella').first);
    await tester.pumpAndSettle();
    expect(find.text('Cancellare lo spot?'), findsOneWidget);
    await tester.tap(find.text('Cancella').last);
    await tester.pumpAndSettle();

    expect(spots.deleteCalls, ['s1']);
    expect(find.text('Spot 1'), findsNothing);
    expect(find.text('Spot 2'), findsOneWidget);
    expect(find.text('Spot cancellato'), findsOneWidget);
  });

  testWidgets('annullando non cancella nulla', (tester) async {
    final spots = FakeSpotsRepository(mine: [makeMySpot(1)]);
    await openMySpots(tester, spots);

    await tester.tap(find.byTooltip('Cancella'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(spots.deleteCalls, isEmpty);
    expect(find.text('Spot 1'), findsOneWidget);
  });

  testWidgets('cancellazione fallita: messaggio e lo spot resta', (
    tester,
  ) async {
    final spots = FakeSpotsRepository(mine: [makeMySpot(1)])
      ..deleteError = const NetworkFailure();
    await openMySpots(tester, spots);

    await tester.tap(find.byTooltip('Cancella'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancella').last);
    await tester.pumpAndSettle();

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
    expect(find.text('Spot 1'), findsOneWidget);
  });

  testWidgets('errore di caricamento: messaggio e Riprova', (tester) async {
    final spots = FakeSpotsRepository(mine: [makeMySpot(1)])
      ..listError = const NetworkFailure();
    await openMySpots(tester, spots);

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    spots.listError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Spot 1'), findsOneWidget);
  });
}
