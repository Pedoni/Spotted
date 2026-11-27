import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/admin/domain/entities/admin_action.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';
import 'package:spotted/features/reports/presentation/widgets/report_skeletons.dart';

import '../../../helpers/fake_admin.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeAdminRepository admin;

  Future<void> openProfile(
    WidgetTester tester,
    FakeAdminRepository repository,
  ) async {
    admin = repository;
    await pumpApp(tester, admin: repository, screenSize: tallScreen);
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
  }

  Future<void> openPanel(
    WidgetTester tester, {
    List<dynamic>? reports,
    FakeAdminRepository? repository,
  }) async {
    await openProfile(
      tester,
      repository ??
          FakeAdminRepository(
            admin: true,
            reports: [
              makeAdminReport(1),
              makeAdminReport(2, comment: true, channelName: 'Spotted Roma'),
            ],
          ),
    );
    await tester.tap(find.text('Pannello admin'));
    await tester.pumpAndSettle();
  }

  group('voce nel Profilo', () {
    testWidgets('un admin la vede', (tester) async {
      await openProfile(tester, FakeAdminRepository(admin: true));

      expect(find.text('Amministrazione'), findsOneWidget);
      expect(find.text('Pannello admin'), findsOneWidget);
    });

    testWidgets('chi non è admin non la vede', (tester) async {
      await openProfile(tester, FakeAdminRepository());

      expect(find.text('Amministrazione'), findsNothing);
      expect(find.text('Pannello admin'), findsNothing);
    });

    testWidgets('se il controllo fallisce resta nascosta', (tester) async {
      await openProfile(
        tester,
        FakeAdminRepository(admin: true)..adminError = const NetworkFailure(),
      );

      expect(find.text('Pannello admin'), findsNothing);
    });
  });

  group('pannello', () {
    testWidgets('mostra le segnalazioni di tutti i canali', (tester) async {
      await openPanel(tester);

      expect(find.text('Pannello admin'), findsOneWidget);
      expect(find.text('Testo spot 1'), findsOneWidget);
      expect(find.text('Testo commento 2'), findsOneWidget);
      expect(find.textContaining('Spotted Pisa'), findsOneWidget);
      expect(find.textContaining('Spotted Roma'), findsOneWidget);
      expect(find.textContaining('Segnalazione su uno spot'), findsOneWidget);
      expect(
        find.textContaining('Segnalazione su un commento'),
        findsOneWidget,
      );
    });

    testWidgets('motivo, dettagli e numero di segnalazioni', (tester) async {
      await openPanel(
        tester,
        repository: FakeAdminRepository(
          admin: true,
          reports: [
            makeAdminReport(
              1,
              reason: ReportReason.hate,
              details: 'Insulta una persona',
              count: 3,
            ),
          ],
        ),
      );

      expect(find.text('Odio o discriminazione'), findsOneWidget);
      expect(find.text('Insulta una persona'), findsOneWidget);
      expect(find.text('3 segnalazioni'), findsOneWidget);
    });

    testWidgets('una sola segnalazione: niente numero', (tester) async {
      await openPanel(tester);

      expect(find.textContaining('segnalazioni'), findsNothing);
    });

    testWidgets('senza segnalazioni: messaggio', (tester) async {
      await openPanel(tester, repository: FakeAdminRepository(admin: true));

      expect(find.text('Nessuna segnalazione aperta'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
    });

    testWidgets('mentre carica c è lo scheletro, non uno spinner', (
      tester,
    ) async {
      await openProfile(
        tester,
        FakeAdminRepository(admin: true, reports: [makeAdminReport(1)]),
      );
      final gate = Completer<void>();
      admin.listGate = gate;

      await tester.tap(find.text('Pannello admin'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ReportCardsSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Testo spot 1'), findsOneWidget);
    });

    testWidgets('errore: messaggio e Riprova', (tester) async {
      await openProfile(tester, FakeAdminRepository(admin: true));
      admin.listError = const PermissionFailure();
      await tester.tap(find.text('Pannello admin'));
      await tester.pumpAndSettle();

      expect(
        find.text('Non hai i permessi per eseguire questa azione'),
        findsOneWidget,
      );

      admin
        ..listError = null
        ..reports = [makeAdminReport(1)];
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(find.text('Testo spot 1'), findsOneWidget);
    });

    testWidgets('un contenuto già nascosto lo dice e non si nasconde ancora', (
      tester,
    ) async {
      await openPanel(
        tester,
        repository: FakeAdminRepository(
          admin: true,
          reports: [makeAdminReport(1, hidden: true)],
        ),
      );

      expect(find.text('Già nascosto'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Nascondi'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Rimuovi'), findsOneWidget);
    });

    testWidgets('un commento si nasconde ma non si rimuove', (tester) async {
      await openPanel(
        tester,
        repository: FakeAdminRepository(
          admin: true,
          reports: [makeAdminReport(1, comment: true)],
        ),
      );

      expect(find.widgetWithText(TextButton, 'Nascondi'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Rimuovi'), findsNothing);
    });
  });

  group('azioni', () {
    testWidgets('Ignora chiude la segnalazione e la toglie', (tester) async {
      await openPanel(tester);

      await tester.tap(find.text('Ignora').first);
      await tester.pumpAndSettle();

      expect(admin.actCalls.single, (
        reportId: 'r1',
        action: AdminAction.dismiss,
      ));
      expect(find.text('Segnalazione ignorata'), findsOneWidget);
      expect(find.text('Testo spot 1'), findsNothing);
      expect(find.text('Testo commento 2'), findsOneWidget);
    });

    testWidgets('Risolvi chiude la segnalazione', (tester) async {
      await openPanel(tester);

      await tester.tap(find.text('Risolvi').first);
      await tester.pumpAndSettle();

      expect(admin.actCalls.single.action, AdminAction.resolve);
      expect(find.text('Segnalazione risolta'), findsOneWidget);
    });

    testWidgets('Nascondi nasconde il contenuto, senza conferma', (
      tester,
    ) async {
      await openPanel(tester);

      await tester.tap(find.text('Nascondi').first);
      await tester.pumpAndSettle();

      expect(admin.actCalls.single, (
        reportId: 'r1',
        action: AdminAction.hide,
      ));
      expect(find.text('Spot nascosto'), findsOneWidget);
    });

    testWidgets('nascondere un commento lo dice', (tester) async {
      await openPanel(
        tester,
        repository: FakeAdminRepository(
          admin: true,
          reports: [makeAdminReport(1, comment: true)],
        ),
      );

      await tester.tap(find.text('Nascondi'));
      await tester.pumpAndSettle();

      expect(find.text('Commento nascosto'), findsOneWidget);
    });

    testWidgets('Rimuovi chiede conferma: annullando non succede niente', (
      tester,
    ) async {
      await openPanel(tester);

      await tester.tap(find.text('Rimuovi').first);
      await tester.pumpAndSettle();
      expect(find.text('Rimuovere lo spot?'), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(admin.actCalls, isEmpty);
      expect(find.text('Testo spot 1'), findsOneWidget);
    });

    testWidgets('Rimuovi dopo la conferma rimuove lo spot', (tester) async {
      await openPanel(tester);

      await tester.tap(find.text('Rimuovi').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Rimuovi'),
        ),
      );
      await tester.pumpAndSettle();

      expect(admin.actCalls.single, (
        reportId: 'r1',
        action: AdminAction.remove,
      ));
      expect(find.text('Spot rimosso'), findsOneWidget);
      expect(find.text('Testo spot 1'), findsNothing);
    });

    testWidgets('errore: messaggio e la segnalazione resta', (tester) async {
      await openPanel(tester);
      admin.actError = const NetworkFailure();

      await tester.tap(find.text('Ignora').first);
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('Testo spot 1'), findsOneWidget);
    });

    testWidgets('mentre agisce i pulsanti di quella segnalazione sono fermi', (
      tester,
    ) async {
      await openPanel(tester);
      final gate = Completer<void>();
      admin.actGate = gate;

      await tester.tap(find.text('Ignora').first);
      await tester.pump();

      final first = find.ancestor(
        of: find.text('Testo spot 1'),
        matching: find.byType(Card),
      );
      for (final button in tester.widgetList<TextButton>(
        find.descendant(of: first, matching: find.byType(TextButton)),
      )) {
        expect(button.onPressed, isNull);
      }

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Testo spot 1'), findsNothing);
    });
  });

  testWidgets('scorrendo carica la pagina successiva', (tester) async {
    await openPanel(
      tester,
      repository: FakeAdminRepository(
        admin: true,
        reports: [for (var i = 1; i <= 25; i++) makeAdminReport(i)],
      ),
    );
    expect(admin.listCalls, hasLength(1));

    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    expect(admin.listCalls.last.offset, 20);
    // Arrivate le altre, si scorre fino all'ultima.
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(find.text('Testo spot 25'), findsOneWidget);
  });
}
