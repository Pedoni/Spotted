import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  Future<void> openChannel(
    WidgetTester tester,
    FakeSpotsRepository spots,
  ) async {
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots: spots,
    );
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra gli spot del canale, senza autore', (tester) async {
    await openChannel(
      tester,
      FakeSpotsRepository(
        spots: [
          makeSpot(1, title: 'Cerco il mio ombrello'),
          makeSpot(2, title: 'Complimenti al barista'),
          makeSpot(3, channelId: 'altro', title: 'Di un altro canale'),
        ],
      ),
    );

    expect(find.text('Cerco il mio ombrello'), findsOneWidget);
    expect(find.text('Complimenti al barista'), findsOneWidget);
    expect(find.text('Testo dello spot 1'), findsOneWidget);
    expect(find.text('Di un altro canale'), findsNothing);
  });

  testWidgets('canale senza spot: invito a scrivere il primo', (tester) async {
    await openChannel(tester, FakeSpotsRepository());

    expect(find.text('Ancora nessuno spot. Scrivi il primo!'), findsOneWidget);
  });

  testWidgets('errore: messaggio e Riprova', (tester) async {
    final spots = FakeSpotsRepository(spots: [makeSpot(1)])
      ..listError = const NetworkFailure();
    await openChannel(tester, spots);

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    spots.listError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Spot 1'), findsOneWidget);
  });

  testWidgets('scorrendo carica la pagina successiva', (tester) async {
    final spots = FakeSpotsRepository(spots: List.generate(30, makeSpot));
    await openChannel(tester, spots);
    expect(spots.listCalls, hasLength(1));

    await tester.dragUntilVisible(
      find.text('Spot 29'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(spots.listCalls.map((c) => c.offset), [0, 20]);
    expect(find.text('Spot 29'), findsOneWidget);
  });
}
