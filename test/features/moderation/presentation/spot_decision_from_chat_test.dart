import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/chat/domain/entities/chat_message_kind.dart';
import 'package:spotted/features/chat/presentation/widgets/system_message_tile.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeSpotsRepository spots;
  late FakeModerationRepository moderation;
  late FakeChatRepository chat;

  /// Il proprietario apre la scheda Chat, la chat con l'utente e, da lì, lo
  /// spot inviato.
  Future<void> openSpotFromChat(
    WidgetTester tester, {
    bool owner = true,
    SpotStatus status = SpotStatus.pending,
  }) async {
    spots = FakeSpotsRepository(
      spots: [makeSpot(1, title: 'Ombrello perso', status: status)],
    );
    moderation = FakeModerationRepository(
      ownedChannelIds: owner ? {'c1'} : const {},
      spotsRepository: spots,
    );
    chat = FakeChatRepository(
      chats: [makeChannelChat(1, owner: owner)],
      messages: {
        'cc1': [
          makeMessage(
            1,
            content: 'Ombrello perso',
            isMine: !owner,
            kind: ChatMessageKind.spotSent,
            spotId: 's1',
          ),
        ],
      },
    );
    await pumpApp(
      tester,
      spots: spots,
      moderation: moderation,
      chat: chat,
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SystemMessageTile));
    await tester.pumpAndSettle();
    // Il pulsante con il nome dello spot: siamo nel suo dettaglio.
    expect(find.text('Ombrello perso'), findsOneWidget);
  }

  final publishInSheet = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.widgetWithText(FilledButton, 'Pubblica'),
  );

  testWidgets('il proprietario vede Rifiuta e Pubblica sullo spot in attesa', (
    tester,
  ) async {
    await openSpotFromChat(tester);

    expect(find.widgetWithText(OutlinedButton, 'Rifiuta'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Pubblica'), findsOneWidget);
    expect(find.text('In attesa di approvazione'), findsOneWidget);
  });

  testWidgets('Pubblica: sceglie i tag e lo spot esce, i pulsanti spariscono', (
    tester,
  ) async {
    await openSpotFromChat(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Pubblica'));
    await tester.pumpAndSettle();
    expect(find.text('Scegli i tag dello spot'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Crush'));
    await tester.pump();
    await tester.tap(publishInSheet);
    await tester.pumpAndSettle();

    expect(moderation.approveCalls.single.spotId, 's1');
    expect(moderation.approveCalls.single.tags, ['crush']);
    expect(find.text('Spot pubblicato'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Rifiuta'), findsNothing);
    expect(find.text('In attesa di approvazione'), findsNothing);
    // Ora è pubblicato, con i suoi tag.
    expect(find.text('Crush'), findsOneWidget);
  });

  testWidgets('Rifiuta: conferma, poi lo spot risulta rifiutato', (
    tester,
  ) async {
    await openSpotFromChat(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Rifiuta'));
    await tester.pumpAndSettle();
    expect(find.text('Rifiutare lo spot?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Rifiuta'),
      ),
    );
    await tester.pumpAndSettle();

    expect(moderation.rejectCalls, ['s1']);
    expect(find.text('Spot rifiutato'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Rifiuta'), findsNothing);
    expect(
      find.text('Rifiutato dal proprietario del canale'),
      findsOneWidget,
    );
  });

  testWidgets('annullando la conferma non succede niente', (tester) async {
    await openSpotFromChat(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Rifiuta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(moderation.rejectCalls, isEmpty);
    expect(find.widgetWithText(OutlinedButton, 'Rifiuta'), findsOneWidget);
  });

  testWidgets('errore: messaggio e i pulsanti restano', (tester) async {
    await openSpotFromChat(tester);
    moderation.approveError = const PermissionFailure();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Rifiuta'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Rifiuta'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Rifiuta'), findsOneWidget);
  });

  testWidgets('chi ha inviato lo spot non ha i pulsanti', (tester) async {
    await openSpotFromChat(tester, owner: false);

    expect(find.widgetWithText(OutlinedButton, 'Rifiuta'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Pubblica'), findsNothing);
    expect(find.text('In attesa di approvazione'), findsOneWidget);
  });

  testWidgets('uno spot già pubblicato non ha i pulsanti', (tester) async {
    await openSpotFromChat(tester, status: SpotStatus.published);

    expect(find.widgetWithText(OutlinedButton, 'Rifiuta'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Pubblica'), findsNothing);
  });

  testWidgets('decidere aggiorna la chat: ricarica i messaggi e l elenco', (
    tester,
  ) async {
    await openSpotFromChat(tester);
    final listCallsBefore = chat.listCalls.length;
    final messageCallsBefore = chat.messageCalls.length;

    await tester.tap(find.widgetWithText(OutlinedButton, 'Rifiuta'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Rifiuta'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();

    // Tornando nella chat i messaggi sono stati ricaricati (c'è l'esito).
    expect(chat.messageCalls.length, greaterThan(messageCallsBefore));
    // E tornando all'elenco, la chat ha il nuovo ultimo messaggio.
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    expect(chat.listCalls.length, greaterThan(listCallsBefore));
  });
}
