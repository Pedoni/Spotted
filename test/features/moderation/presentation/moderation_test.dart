import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/comments/domain/entities/comment_status.dart';
import 'package:spotted/features/moderation/domain/entities/moderation_status.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  late FakeSpotsRepository spots;
  late FakeCommentsRepository comments;
  late FakeModerationRepository moderation;

  /// Apre la home → Canali → il canale → lo spot "Ombrello perso".
  Future<void> openSpot(
    WidgetTester tester, {
    bool owner = true,
    bool ownerCheckFails = false,
    List<SpotStatus> statuses = const [SpotStatus.published],
  }) async {
    spots = FakeSpotsRepository(
      spots: [
        makeSpot(
          1,
          title: 'Ombrello perso',
          stats: const SpotStats(commentCount: 2),
          status: statuses.single,
        ),
      ],
    );
    comments = FakeCommentsRepository(
      comments: [makeComment(1), makeComment(2)],
    );
    moderation = FakeModerationRepository(
      ownedChannelIds: owner ? {'c1'} : {},
      spotsRepository: spots,
      commentsRepository: comments,
    );
    if (ownerCheckFails) moderation.ownerError = const NetworkFailure();
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots: spots,
      comments: comments,
      moderation: moderation,
    );
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
  }

  Future<void> openSpotDetail(WidgetTester tester) async {
    await tester.tap(find.text('Ombrello perso'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseFromMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Strumenti del proprietario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  group('menu del proprietario sullo spot', () {
    testWidgets('chi non è proprietario non vede gli strumenti', (
      tester,
    ) async {
      await openSpot(tester, owner: false);
      await openSpotDetail(tester);

      expect(find.byTooltip('Strumenti del proprietario'), findsNothing);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
      expect(find.byIcon(Icons.shield_outlined), findsNothing);
    });

    testWidgets('se il controllo del proprietario fallisce niente strumenti', (
      tester,
    ) async {
      await openSpot(tester, ownerCheckFails: true);
      await openSpotDetail(tester);

      expect(find.text('Ombrello perso'), findsOneWidget);
      expect(find.byTooltip('Strumenti del proprietario'), findsNothing);
    });

    testWidgets("il proprietario vede l'autore dello spot", (tester) async {
      await openSpot(tester);
      await openSpotDetail(tester);

      await chooseFromMenu(tester, 'Vedi autore');

      expect(find.text('Autore dello spot'), findsOneWidget);
      expect(find.text('@giulia_77'), findsOneWidget);
      expect(moderation.authorCalls, ['s1']);

      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();
      expect(find.text('Autore dello spot'), findsNothing);
    });

    testWidgets("errore nel leggere l'autore: messaggio", (tester) async {
      await openSpot(tester);
      moderation.authorError = const PermissionFailure();
      await openSpotDetail(tester);

      await chooseFromMenu(tester, 'Vedi autore');

      expect(find.text('Autore dello spot'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('nasconde lo spot: etichetta e ripristino', (tester) async {
      await openSpot(tester);
      await openSpotDetail(tester);

      await chooseFromMenu(tester, 'Nascondi spot');

      expect(moderation.statusCalls.single, (
        spotId: 's1',
        status: ModerationStatus.hidden,
      ));
      expect(find.text('Spot nascosto'), findsOneWidget);
      // Dopo il ricaricamento lo spot ha l'etichetta e il menu offre il
      // ripristino.
      expect(
        find.text('Nascosto dal proprietario del canale'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
      await chooseFromMenu(tester, 'Ripristina spot');

      expect(moderation.statusCalls.last.status, ModerationStatus.published);
      expect(find.text('Spot ripristinato'), findsOneWidget);
      expect(
        find.text('Nascosto dal proprietario del canale'),
        findsNothing,
      );
    });

    testWidgets('rimuove lo spot dopo la conferma e torna al canale', (
      tester,
    ) async {
      await openSpot(tester);
      await openSpotDetail(tester);

      await chooseFromMenu(tester, 'Rimuovi spot');
      expect(find.text('Rimuovere lo spot?'), findsOneWidget);
      // La conferma ha lo stesso testo della voce di menu.
      await tester.tap(find.widgetWithText(TextButton, 'Rimuovi spot'));
      await tester.pumpAndSettle();

      expect(moderation.statusCalls.single, (
        spotId: 's1',
        status: ModerationStatus.removed,
      ));
      expect(find.text('Spot rimosso'), findsOneWidget);
      // Siamo tornati al canale, che non mostra più lo spot.
      expect(find.text('Ombrello perso'), findsNothing);
      expect(find.text('Spotted Pisa'), findsWidgets);
    });

    testWidgets('annullando la conferma lo spot resta', (tester) async {
      await openSpot(tester);
      await openSpotDetail(tester);

      await chooseFromMenu(tester, 'Rimuovi spot');
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(moderation.statusCalls, isEmpty);
      expect(find.text('Ombrello perso'), findsOneWidget);
    });

    testWidgets('errore nel cambiare lo stato: messaggio e nulla cambia', (
      tester,
    ) async {
      await openSpot(tester);
      moderation.statusError = const PermissionFailure();
      await openSpotDetail(tester);

      await chooseFromMenu(tester, 'Nascondi spot');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Spot nascosto'), findsNothing);
      expect(
        find.text('Nascosto dal proprietario del canale'),
        findsNothing,
      );
    });
  });

  group('moderazione dei commenti', () {
    testWidgets('il proprietario nasconde e ripristina un commento', (
      tester,
    ) async {
      await openSpot(tester);
      await openSpotDetail(tester);
      expect(find.text('2 commenti'), findsOneWidget);

      await tester.tap(find.byTooltip('Nascondi commento').first);
      await tester.pumpAndSettle();

      expect(moderation.commentCalls.single, (commentId: 'k1', hidden: true));
      expect(comments.comments.first.status, CommentStatus.hidden);
      expect(find.text('Commento nascosto'), findsOneWidget);
      expect(find.text('Nascosto'), findsOneWidget);
      // Il conteggio ignora i commenti nascosti.
      expect(find.text('1 commento'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.byTooltip('Ripristina commento'));
      await tester.pumpAndSettle();

      expect(moderation.commentCalls.last, (commentId: 'k1', hidden: false));
      expect(find.text('Commento ripristinato'), findsOneWidget);
      expect(find.text('Nascosto'), findsNothing);
      expect(find.text('2 commenti'), findsOneWidget);
    });

    testWidgets('chi non è proprietario non ha il pulsante', (tester) async {
      await openSpot(tester, owner: false);
      await openSpotDetail(tester);

      expect(find.byTooltip('Nascondi commento'), findsNothing);
    });

    testWidgets("errore: messaggio e il commento resta com'era", (
      tester,
    ) async {
      await openSpot(tester);
      moderation.commentError = const PermissionFailure();
      await openSpotDetail(tester);

      await tester.tap(find.byTooltip('Nascondi commento').first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Commento nascosto'), findsNothing);
      expect(find.text('2 commenti'), findsOneWidget);
    });
  });

  group('pagina Moderazione', () {
    testWidgets('il proprietario la apre dal canale e ripristina uno spot', (
      tester,
    ) async {
      await openSpot(tester, statuses: [SpotStatus.hidden]);

      await tester.tap(find.byIcon(Icons.shield_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Moderazione'), findsOneWidget);
      expect(find.text('Ombrello perso'), findsOneWidget);
      expect(moderation.hiddenCalls.single.channelId, 'c1');

      await tester.tap(find.text('Ripristina spot'));
      await tester.pumpAndSettle();

      expect(moderation.statusCalls.single, (
        spotId: 's1',
        status: ModerationStatus.published,
      ));
      expect(find.text('Spot ripristinato'), findsOneWidget);
      expect(find.text('Nessuno spot nascosto'), findsOneWidget);
    });

    testWidgets('senza spot nascosti: messaggio', (tester) async {
      await openSpot(tester);

      await tester.tap(find.byIcon(Icons.shield_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Nessuno spot nascosto'), findsOneWidget);
    });

    testWidgets('errore: messaggio e Riprova', (tester) async {
      await openSpot(tester);
      moderation.listError = const NetworkFailure();

      await tester.tap(find.byIcon(Icons.shield_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      moderation.listError = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(find.text('Nessuno spot nascosto'), findsOneWidget);
    });
  });
}
