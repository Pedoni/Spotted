import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  Future<void> openSpot(
    WidgetTester tester, {
    FakeSpotsRepository? spots,
    FakeCommentsRepository? comments,
  }) async {
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots:
          spots ??
          FakeSpotsRepository(
            spots: [
              makeSpot(
                1,
                title: 'Ombrello perso',
                stats: const SpotStats(likeCount: 2, commentCount: 3),
              ),
            ],
          ),
      comments: comments,
    );
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ombrello perso'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra lo spot con numero di commenti e i commenti', (
    tester,
  ) async {
    await openSpot(
      tester,
      comments: FakeCommentsRepository(
        comments: [
          makeComment(1),
          makeComment(2, isSpotAuthor: true),
          makeComment(3, authorUsername: 'anna'),
        ],
      ),
    );

    expect(find.text('Ombrello perso'), findsOneWidget);
    expect(find.text('3 commenti'), findsOneWidget);
    expect(find.text('Commento 1'), findsOneWidget);
    expect(find.textContaining('@luigi', findRichText: true), findsOneWidget);
    expect(find.textContaining('@anna', findRichText: true), findsOneWidget);
    // Chi ha scritto lo spot commenta senza nome.
    expect(
      find.textContaining('Autore del post', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('senza commenti: invito a scrivere il primo', (tester) async {
    await openSpot(tester);

    expect(
      find.text('Ancora nessun commento. Scrivi il primo!'),
      findsOneWidget,
    );
  });

  testWidgets('errore nel caricare i commenti: messaggio e Riprova', (
    tester,
  ) async {
    final comments = FakeCommentsRepository(comments: [makeComment(1)])
      ..listError = const NetworkFailure();
    await openSpot(tester, comments: comments);

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    comments.listError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Commento 1'), findsOneWidget);
  });

  testWidgets('pubblica un commento: compare in cima, il campo si svuota', (
    tester,
  ) async {
    final comments = FakeCommentsRepository(comments: [makeComment(1)]);
    await openSpot(tester, comments: comments);

    await tester.enterText(find.byType(TextField), '  Il mio commento  ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(comments.addCalls.single, (
      spotId: 's1',
      content: 'Il mio commento',
    ));
    expect(find.text('Il mio commento'), findsOneWidget);
    expect(
      find.textContaining('@mario_88', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('4 commenti'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('un commento vuoto non viene inviato', (tester) async {
    final comments = FakeCommentsRepository();
    await openSpot(tester, comments: comments);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(comments.addCalls, isEmpty);
  });

  testWidgets('invio fallito: messaggio e il testo resta nel campo', (
    tester,
  ) async {
    final comments = FakeCommentsRepository()
      ..addError = const NetworkFailure();
    await openSpot(tester, comments: comments);

    await tester.enterText(find.byType(TextField), 'Il mio commento');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
    expect(find.text('Il mio commento'), findsOneWidget);
    expect(find.text('3 commenti'), findsOneWidget);
  });

  testWidgets('like a un commento', (tester) async {
    final comments = FakeCommentsRepository(
      comments: [makeComment(1, likeCount: 4)],
    );
    await openSpot(tester, comments: comments);

    await tester.tap(find.byIcon(Icons.favorite_border).last);
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
    expect(comments.likeCalls.single, (commentId: 'k1', liked: true));
  });

  testWidgets("like rifiutato su un commento: torna com'era", (tester) async {
    final comments = FakeCommentsRepository(
      comments: [makeComment(1, likeCount: 4)],
    )..likeError = const NetworkFailure();
    await openSpot(tester, comments: comments);

    await tester.tap(find.byIcon(Icons.favorite_border).last);
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
  });

  testWidgets('like allo spot dalla pagina di dettaglio', (tester) async {
    final spots = FakeSpotsRepository(
      spots: [
        makeSpot(
          1,
          title: 'Ombrello perso',
          stats: const SpotStats(likeCount: 2),
        ),
      ],
    );
    await openSpot(tester, spots: spots);

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(spots.likeCalls.single, (spotId: 's1', liked: true));
  });

  testWidgets('si cancellano solo i propri commenti, dopo la conferma', (
    tester,
  ) async {
    final comments = FakeCommentsRepository(
      comments: [
        makeComment(1),
        makeComment(2, isMine: true, content: 'Il mio'),
      ],
    );
    await openSpot(tester, comments: comments);

    // Un solo cestino: quello del commento mio.
    expect(find.byTooltip('Cancella il commento'), findsOneWidget);

    await tester.tap(find.byTooltip('Cancella il commento'));
    await tester.pumpAndSettle();
    expect(find.text('Cancellare il commento?'), findsOneWidget);
    await tester.tap(find.text('Cancella'));
    await tester.pumpAndSettle();

    expect(comments.deleteCalls, ['k2']);
    expect(find.text('Il mio'), findsNothing);
    expect(find.text('Commento 1'), findsOneWidget);
    expect(find.text('Commento cancellato'), findsOneWidget);
    expect(find.text('2 commenti'), findsOneWidget);
  });

  testWidgets('annullando la cancellazione non succede nulla', (tester) async {
    final comments = FakeCommentsRepository(
      comments: [makeComment(1, isMine: true, content: 'Il mio')],
    );
    await openSpot(tester, comments: comments);

    await tester.tap(find.byTooltip('Cancella il commento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(comments.deleteCalls, isEmpty);
    expect(find.text('Il mio'), findsOneWidget);
  });

  testWidgets('lo spot e i commenti mostrano data e ora', (tester) async {
    await openSpot(
      tester,
      comments: FakeCommentsRepository(comments: [makeComment(1)]),
    );

    // Lo spot (makeSpot(1)) e il commento (makeComment(1)) sono di un minuto
    // prima di mezzanotte.
    expect(find.text('31 dic 2025 · 23:59'), findsOneWidget);
    expect(
      find.textContaining('31 dic 2025 · 23:59', findRichText: true),
      findsNWidgets(2),
    );
  });
}
