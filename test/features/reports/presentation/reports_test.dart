import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/comments/presentation/widgets/comment_tile.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';
import 'package:spotted/features/reports/domain/entities/report_resolution.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  late FakeReportsRepository reports;
  late FakeCommentsRepository comments;

  /// Il pulsante "Segnala" dello spot (barra in alto).
  final spotFlag = find.descendant(
    of: find.byType(AppBar),
    matching: find.byTooltip('Segnala'),
  );

  /// I pulsanti "Segnala" dei commenti.
  final commentFlags = find.descendant(
    of: find.byType(CommentTile),
    matching: find.byTooltip('Segnala'),
  );

  /// Apre il canale (e, se [openSpot], lo spot "Ombrello perso").
  Future<void> openChannel(
    WidgetTester tester, {
    bool owner = false,
    bool openSpot = true,
    List<ChannelReportSeed> seeds = const [],
  }) async {
    reports = FakeReportsRepository(
      reports: [for (final s in seeds) makeReport(s.i, kind: s.kind)],
    );
    comments = FakeCommentsRepository(
      comments: [
        makeComment(1),
        makeComment(2, isMine: true),
      ],
    );
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots: FakeSpotsRepository(
        spots: [makeSpot(1, title: 'Ombrello perso')],
      ),
      comments: comments,
      moderation: FakeModerationRepository(
        ownedChannelIds: owner ? {'c1'} : {},
      ),
      reports: reports,
    );
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    if (openSpot) {
      await tester.tap(find.text('Ombrello perso'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> sendReport(
    WidgetTester tester, {
    String? reason,
    String? details,
  }) async {
    if (reason != null) {
      await tester.tap(find.text(reason));
      await tester.pumpAndSettle();
    }
    if (details != null) {
      await tester.enterText(find.byType(TextField).last, details);
    }
    await tester.tap(find.text('Invia segnalazione'));
    await tester.pumpAndSettle();
  }

  group('segnalare uno spot', () {
    testWidgets('sceglie il motivo, scrive i dettagli e invia', (
      tester,
    ) async {
      await openChannel(tester);

      await tester.tap(spotFlag);
      await tester.pumpAndSettle();
      expect(find.text('Segnala il contenuto'), findsOneWidget);

      await sendReport(tester, reason: 'Spam', details: '  Pubblicità  ');

      expect(reports.spotCalls.single, (
        spotId: 's1',
        reason: ReportReason.spam,
        details: 'Pubblicità',
      ));
      expect(find.text('Segnalazione inviata'), findsOneWidget);
      expect(find.text('Segnala il contenuto'), findsNothing);
    });

    testWidgets('senza motivo non si può inviare', (tester) async {
      await openChannel(tester);

      await tester.tap(spotFlag);
      await tester.pumpAndSettle();

      final send = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Invia segnalazione'),
      );
      expect(send.onPressed, isNull);
    });

    testWidgets('annullando non parte nessuna segnalazione', (tester) async {
      await openChannel(tester);

      await tester.tap(spotFlag);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(reports.spotCalls, isEmpty);
      expect(find.text('Segnala il contenuto'), findsNothing);
    });

    testWidgets('già segnalato: messaggio dedicato', (tester) async {
      await openChannel(tester);
      reports.reportError = const ConflictFailure();

      await tester.tap(spotFlag);
      await tester.pumpAndSettle();
      await sendReport(tester, reason: 'Altro');

      expect(find.text('Hai già segnalato questo contenuto'), findsOneWidget);
    });

    testWidgets('contenuto proprio: messaggio dedicato', (tester) async {
      await openChannel(tester);
      reports.reportError = const PermissionFailure();

      await tester.tap(spotFlag);
      await tester.pumpAndSettle();
      await sendReport(tester, reason: 'Altro');

      expect(find.text('Non puoi segnalare un tuo contenuto'), findsOneWidget);
    });

    testWidgets('errore di rete: messaggio generico', (tester) async {
      await openChannel(tester);
      reports.reportError = const NetworkFailure();

      await tester.tap(spotFlag);
      await tester.pumpAndSettle();
      await sendReport(tester, reason: 'Odio o discriminazione');

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
    });
  });

  group('segnalare un commento', () {
    testWidgets('invia la segnalazione sul commento', (tester) async {
      await openChannel(tester);

      await tester.tap(commentFlags);
      await tester.pumpAndSettle();
      await sendReport(tester, reason: 'Offensivo');

      expect(reports.commentCalls.single, (
        commentId: 'k1',
        reason: ReportReason.offensive,
        details: null,
      ));
      expect(reports.spotCalls, isEmpty);
      expect(find.text('Segnalazione inviata'), findsOneWidget);
    });

    testWidgets('i propri commenti non si segnalano', (tester) async {
      await openChannel(tester);

      // Due commenti, di cui uno mio: un solo pulsante sui commenti.
      expect(commentFlags, findsOneWidget);
      expect(spotFlag, findsOneWidget);
    });
  });

  group('scheda Segnalazioni del proprietario', () {
    Future<void> openReports(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.shield_outlined));
      await tester.pumpAndSettle();
    }

    testWidgets('mostra le segnalazioni aperte con motivo e dettagli', (
      tester,
    ) async {
      await openChannel(
        tester,
        owner: true,
        openSpot: false,
        seeds: const [
          ChannelReportSeed(1),
          ChannelReportSeed(2, kind: ReportKind.comment),
        ],
      );

      await openReports(tester);

      expect(find.text('Moderazione'), findsOneWidget);
      expect(find.text('Segnalazioni'), findsOneWidget);
      expect(find.text('Testo spot 1'), findsOneWidget);
      expect(find.text('Testo commento 2'), findsOneWidget);
      expect(find.textContaining('Segnalazione su uno spot'), findsOneWidget);
      expect(
        find.textContaining('Segnalazione su un commento'),
        findsOneWidget,
      );
      expect(find.text('Spam'), findsNWidgets(2));
      expect(reports.listCalls.single.channelId, 'c1');
    });

    testWidgets('senza segnalazioni: messaggio', (tester) async {
      await openChannel(tester, owner: true, openSpot: false);

      await openReports(tester);

      expect(find.text('Nessuna segnalazione aperta'), findsOneWidget);
    });

    testWidgets('Risolvi chiude la segnalazione e la toglie', (tester) async {
      await openChannel(
        tester,
        owner: true,
        openSpot: false,
        seeds: const [ChannelReportSeed(1), ChannelReportSeed(2)],
      );
      await openReports(tester);

      await tester.tap(find.text('Risolvi').first);
      await tester.pumpAndSettle();

      expect(reports.resolveCalls.single, (
        reportId: 'r1',
        resolution: ReportResolution.resolved,
      ));
      expect(find.text('Segnalazione risolta'), findsOneWidget);
      expect(find.text('Testo spot 1'), findsNothing);
      expect(find.text('Testo spot 2'), findsOneWidget);
    });

    testWidgets('Ignora chiude la segnalazione come ignorata', (tester) async {
      await openChannel(
        tester,
        owner: true,
        openSpot: false,
        seeds: const [ChannelReportSeed(1)],
      );
      await openReports(tester);

      await tester.tap(find.text('Ignora'));
      await tester.pumpAndSettle();

      expect(reports.resolveCalls.single, (
        reportId: 'r1',
        resolution: ReportResolution.dismissed,
      ));
      expect(find.text('Segnalazione ignorata'), findsOneWidget);
      expect(find.text('Nessuna segnalazione aperta'), findsOneWidget);
    });

    testWidgets('errore nel chiudere: messaggio e la segnalazione resta', (
      tester,
    ) async {
      await openChannel(
        tester,
        owner: true,
        openSpot: false,
        seeds: const [ChannelReportSeed(1)],
      );
      await openReports(tester);
      reports.resolveError = const NetworkFailure();

      await tester.tap(find.text('Risolvi'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('Testo spot 1'), findsOneWidget);
    });

    testWidgets('errore nel caricare: messaggio e Riprova', (tester) async {
      await openChannel(
        tester,
        owner: true,
        openSpot: false,
        seeds: const [ChannelReportSeed(1)],
      );
      reports.listError = const NetworkFailure();
      await openReports(tester);

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      reports.listError = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(find.text('Testo spot 1'), findsOneWidget);
    });

    testWidgets('toccando una segnalazione si apre lo spot', (tester) async {
      await openChannel(
        tester,
        owner: true,
        openSpot: false,
        seeds: const [ChannelReportSeed(1)],
      );
      await openReports(tester);

      await tester.tap(find.text('Spot segnalato 1'));
      await tester.pumpAndSettle();

      // Il dettaglio dello spot s1.
      expect(find.text('Ombrello perso'), findsOneWidget);
    });
  });
}

/// Una segnalazione da creare nel fake.
class ChannelReportSeed {
  const ChannelReportSeed(this.i, {this.kind = ReportKind.spot});

  final int i;
  final ReportKind kind;
}
