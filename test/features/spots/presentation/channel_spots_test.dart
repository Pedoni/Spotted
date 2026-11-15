import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';

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
      // L'intestazione del canale (copertina, foto, schede) è alta: serve uno
      // schermo alto per vedere più spot.
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
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

  testWidgets('canale senza spot: lo stato vuoto è al centro dello spazio '
      'sotto l intestazione', (tester) async {
    await openChannel(tester, FakeSpotsRepository());

    final empty = tester.getRect(find.byType(EmptyState));
    final screenBottom = tester.getSize(find.byType(Scaffold).last).height;
    // Sotto la barra delle schede (l'ultimo elemento dell'intestazione) e
    // sopra il fondo dello schermo.
    final headerBottom = tester.getRect(find.byType(TabBar)).bottom;
    final above = empty.top - headerBottom;
    final below = screenBottom - empty.bottom;

    expect(above, greaterThan(0));
    expect((above - below).abs(), lessThan(48));
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

  testWidgets('mostra like e commenti di ogni spot', (tester) async {
    await openChannel(
      tester,
      FakeSpotsRepository(
        spots: [
          makeSpot(
            1,
            stats: const SpotStats(
              likeCount: 7,
              commentCount: 3,
              likedByMe: true,
            ),
          ),
        ],
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('toccando il cuore il like si aggiorna subito', (tester) async {
    final spots = FakeSpotsRepository(
      spots: [makeSpot(1, stats: const SpotStats(likeCount: 7))],
    );
    await openChannel(tester, spots);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    expect(find.text('8'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(spots.likeCalls.single, (spotId: 's1', liked: true));

    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();

    expect(find.text('7'), findsOneWidget);
    expect(spots.likeCalls.last, (spotId: 's1', liked: false));
  });

  testWidgets("like rifiutato: torna com'era e c'è il messaggio", (
    tester,
  ) async {
    final spots = FakeSpotsRepository(
      spots: [makeSpot(1, stats: const SpotStats(likeCount: 7))],
    )..likeError = const NetworkFailure();
    await openChannel(tester, spots);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
  });
}
