import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  late FakeSpotsRepository spots;
  late FakeModerationRepository moderation;

  /// Apre Home → Canali → il canale (da proprietario) → Moderazione. La prima
  /// scheda è "Da approvare".
  Future<void> openQueue(
    WidgetTester tester, {
    List<SpotStatus> statuses = const [SpotStatus.pending, SpotStatus.pending],
    bool openModeration = true,
  }) async {
    spots = FakeSpotsRepository(
      spots: [
        for (var i = 0; i < statuses.length; i++)
          makeSpot(i + 1, title: 'Spot ${i + 1}', status: statuses[i]),
      ],
    );
    moderation = FakeModerationRepository(
      ownedChannelIds: {'c1'},
      spotsRepository: spots,
    );
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots: spots,
      moderation: moderation,
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    if (openModeration) {
      await tester.tap(find.byIcon(Icons.shield_rounded));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('la coda mostra gli spot in attesa, e il loro numero', (
    tester,
  ) async {
    await openQueue(
      tester,
      statuses: [SpotStatus.pending, SpotStatus.published, SpotStatus.pending],
    );

    expect(find.text('Da approvare (2)'), findsOneWidget);
    expect(find.text('Spot 1'), findsOneWidget);
    expect(find.text('Spot 3'), findsOneWidget);
    // Quello già pubblicato non è in coda.
    expect(find.text('Spot 2'), findsNothing);
    expect(moderation.pendingCalls.single.channelId, 'c1');
    // Nella coda sono tutti in attesa: nessuna etichetta da ripetere.
    expect(find.text('In attesa di approvazione'), findsNothing);
    expect(find.text('Pubblica'), findsNWidgets(2));
    expect(find.text('Rifiuta'), findsNWidgets(2));
  });

  testWidgets('senza spot in attesa: messaggio e niente numero', (
    tester,
  ) async {
    await openQueue(tester, statuses: [SpotStatus.published]);

    expect(find.text('Da approvare'), findsOneWidget);
    expect(find.text('Nessuno spot da approvare'), findsOneWidget);
    expect(find.textContaining('li pubblichi con i tag'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
  });

  testWidgets('errore: messaggio e Riprova', (tester) async {
    await openQueue(tester, openModeration: false);
    moderation.listError = const NetworkFailure();
    await tester.tap(find.byIcon(Icons.shield_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    moderation.listError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Spot 1'), findsOneWidget);
  });

  group('Pubblica', () {
    testWidgets('chiede i tag: finché non ce n è uno il pulsante è spento', (
      tester,
    ) async {
      await openQueue(tester);

      await tester.tap(find.text('Pubblica').first);
      await tester.pumpAndSettle();

      expect(find.text('Scegli i tag dello spot'), findsOneWidget);
      expect(find.text('Scegli da 1 a 3 tag'), findsOneWidget);
      final publish = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(FilledButton, 'Pubblica'),
      );
      expect(tester.widget<FilledButton>(publish).onPressed, isNull);

      await tester.tap(find.widgetWithText(FilterChip, 'Crush'));
      await tester.pump();
      expect(tester.widget<FilledButton>(publish).onPressed, isNotNull);
    });

    testWidgets('pubblica lo spot con i tag scelti e lo toglie dalla coda', (
      tester,
    ) async {
      await openQueue(tester);

      await tester.tap(find.text('Pubblica').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Crush'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'Esami'));
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(FilledButton, 'Pubblica'),
        ),
      );
      await tester.pumpAndSettle();

      expect(moderation.approveCalls.single.spotId, 's1');
      expect(moderation.approveCalls.single.tags, ['crush', 'esami']);
      expect(find.text('Spot pubblicato'), findsOneWidget);
      // Resta solo l'altro, e il numero scende.
      expect(find.text('Spot 1'), findsNothing);
      expect(find.text('Spot 2'), findsOneWidget);
      expect(find.text('Da approvare (1)'), findsOneWidget);
    });

    testWidgets('chiudendo il foglio senza scegliere non succede niente', (
      tester,
    ) async {
      await openQueue(tester);

      await tester.tap(find.text('Pubblica').first);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Scegli i tag dello spot'), findsNothing);
      expect(moderation.approveCalls, isEmpty);
      expect(find.text('Spot 1'), findsOneWidget);
    });

    testWidgets('errore: messaggio e lo spot resta in coda', (tester) async {
      await openQueue(tester);
      moderation.approveError = const PermissionFailure();

      await tester.tap(find.text('Pubblica').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Crush'));
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(FilledButton, 'Pubblica'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Spot pubblicato'), findsNothing);
      expect(find.text('Spot 1'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('lo spot pubblicato compare nel canale con i suoi tag', (
      tester,
    ) async {
      await openQueue(tester, statuses: [SpotStatus.pending]);

      await tester.tap(find.text('Pubblica'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Meme'));
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(FilledButton, 'Pubblica'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Indietro'));
      await tester.pumpAndSettle();

      expect(find.text('Spot 1'), findsOneWidget);
      expect(find.text('Meme'), findsOneWidget);
    });
  });

  group('Rifiuta', () {
    testWidgets('chiede conferma; annullando lo spot resta', (tester) async {
      await openQueue(tester);

      await tester.tap(find.text('Rifiuta').first);
      await tester.pumpAndSettle();

      expect(find.text('Rifiutare lo spot?'), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(moderation.rejectCalls, isEmpty);
      expect(find.text('Spot 1'), findsOneWidget);
    });

    testWidgets('confermando rifiuta lo spot e lo toglie dalla coda', (
      tester,
    ) async {
      await openQueue(tester);

      await tester.tap(find.text('Rifiuta').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Rifiuta'),
        ),
      );
      await tester.pumpAndSettle();

      expect(moderation.rejectCalls, ['s1']);
      expect(find.text('Spot rifiutato'), findsOneWidget);
      expect(find.text('Spot 1'), findsNothing);
      expect(find.text('Spot 2'), findsOneWidget);
      expect(find.text('Da approvare (1)'), findsOneWidget);
    });

    testWidgets('errore: messaggio e lo spot resta in coda', (tester) async {
      await openQueue(tester);
      moderation.approveError = const NetworkFailure();

      await tester.tap(find.text('Rifiuta').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Rifiuta'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('Spot 1'), findsOneWidget);
    });
  });

  group('dettaglio di uno spot in attesa (proprietario)', () {
    testWidgets('niente commenti, segnalazione né moderazione', (tester) async {
      await openQueue(tester, statuses: [SpotStatus.pending]);

      await tester.tap(find.text('Spot 1'));
      await tester.pumpAndSettle();

      expect(find.text('In attesa di approvazione'), findsOneWidget);
      expect(find.byIcon(Icons.flag_rounded), findsNothing);
      expect(find.text('Scrivi un commento'), findsNothing);
      // Nessun "mi piace": uno spot in attesa non ne ha.
      expect(find.byTooltip('Mi piace'), findsNothing);

      await tester.tap(find.byTooltip('Strumenti del proprietario'));
      await tester.pumpAndSettle();
      expect(find.text('Vedi autore'), findsOneWidget);
      expect(find.text('Nascondi spot'), findsNothing);
      expect(find.text('Rimuovi spot'), findsNothing);
    });
  });
}
