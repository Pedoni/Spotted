import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/presentation/pages/my_spots_page.dart';
import 'package:spotted/features/spots/presentation/pages/spot_detail_page.dart';
import 'package:spotted/features/spots/presentation/widgets/my_spots_carousel.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  /// La card finale del carosello (la freccia ha lo stesso testo nel tooltip).
  Finder viewAllCard() => find.descendant(
    of: find.byType(Card),
    matching: find.text('Visualizza tutti'),
  );

  Future<void> scrollCarousel(WidgetTester tester) async {
    await tester.drag(
      find.byType(MySpotCard).first,
      const Offset(-2000, 0),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('senza spot propri c è il titolo e un invito, senza freccia', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('I miei spot'), findsOneWidget);
    expect(find.text('Non hai ancora pubblicato spot'), findsOneWidget);
    expect(find.byTooltip('Visualizza tutti'), findsNothing);
    expect(find.byType(MySpotCard), findsNothing);
  });

  testWidgets('con pochi spot: titolo, freccia e una card per spot', (
    tester,
  ) async {
    await pumpApp(
      tester,
      spots: FakeSpotsRepository(
        mine: [makeMySpot(1), makeMySpot(2), makeMySpot(3)],
      ),
    );

    expect(find.text('I miei spot'), findsOneWidget);
    expect(find.byTooltip('Visualizza tutti'), findsOneWidget);
    expect(find.byType(MySpotCard), findsNWidgets(3));
    expect(viewAllCard(), findsNothing);
  });

  testWidgets('la card mostra canale, titolo e testo', (
    tester,
  ) async {
    await pumpApp(
      tester,
      spots: FakeSpotsRepository(mine: [makeMySpot(1)]),
    );

    final card = find.byType(MySpotCard);
    expect(
      find.descendant(of: card, matching: find.textContaining('Spotted Pisa')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Spot 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Testo dello spot 1')),
      findsOneWidget,
    );
  });

  testWidgets('con cinque spot non c è "Visualizza tutti"', (tester) async {
    await pumpApp(
      tester,
      spots: FakeSpotsRepository(mine: List.generate(5, makeMySpot)),
    );
    await scrollCarousel(tester);

    expect(find.byType(MySpotCard), findsWidgets);
    expect(viewAllCard(), findsNothing);
  });

  testWidgets('con più di cinque spot le card sono cinque e poi c è '
      '"Visualizza tutti"', (tester) async {
    await pumpApp(
      tester,
      spots: FakeSpotsRepository(mine: List.generate(8, makeMySpot)),
    );
    // Il carosello costruisce solo le card visibili: si scorre fino in fondo.
    final seen = <String>{};
    for (var i = 0; i < 6; i++) {
      for (final card in tester.widgetList<MySpotCard>(
        find.byType(MySpotCard),
      )) {
        seen.add(card.item.spot.id);
      }
      await tester.drag(find.byType(MySpotCard).first, const Offset(-300, 0));
      await tester.pumpAndSettle();
    }

    expect(seen, {'s0', 's1', 's2', 's3', 's4'});
    expect(viewAllCard(), findsOneWidget);
  });

  testWidgets('la freccia porta alla pagina dei propri spot', (tester) async {
    await pumpApp(
      tester,
      spots: FakeSpotsRepository(mine: [makeMySpot(1)]),
    );

    await tester.tap(find.byTooltip('Visualizza tutti'));
    await tester.pumpAndSettle();

    expect(find.byType(MySpotsPage), findsOneWidget);
  });

  testWidgets('"Visualizza tutti" porta alla pagina dei propri spot', (
    tester,
  ) async {
    await pumpApp(
      tester,
      spots: FakeSpotsRepository(mine: List.generate(8, makeMySpot)),
    );
    await scrollCarousel(tester);

    await tester.tap(viewAllCard());
    await tester.pumpAndSettle();

    expect(find.byType(MySpotsPage), findsOneWidget);
  });

  testWidgets('toccando una card si apre lo spot', (tester) async {
    await pumpApp(
      tester,
      spots: FakeSpotsRepository(
        spots: [makeSpot(1)],
        mine: [makeMySpot(1)],
      ),
    );

    await tester.tap(find.byType(MySpotCard));
    await tester.pumpAndSettle();

    expect(find.byType(SpotDetailPage), findsOneWidget);
  });

  testWidgets('errore nel carosello: messaggio e Riprova', (
    tester,
  ) async {
    final spots = FakeSpotsRepository(mine: [makeMySpot(1)])
      ..listError = const NetworkFailure();
    await pumpApp(tester, spots: spots);

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    spots.listError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.byType(MySpotCard), findsOneWidget);
  });
}
