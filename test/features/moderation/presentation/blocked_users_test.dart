import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/moderation/domain/entities/blocked_user.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeModerationRepository moderation;
  late FakeChatRepository chat;

  BlockedUser blockedUser(int i, {String username = 'giulia_77'}) =>
      BlockedUser(
        id: 'b$i',
        username: username,
        createdAt: DateTime(2026).subtract(Duration(minutes: i)),
      );

  Future<void> openChat(
    WidgetTester tester, {
    bool owner = true,
    Set<String> blockedChats = const {},
  }) async {
    moderation = FakeModerationRepository(
      ownedChannelIds: owner ? {'c1'} : const {},
    )..blockedChats = blockedChats;
    chat = FakeChatRepository(chats: [makeChannelChat(1, owner: owner)]);
    await pumpApp(tester, moderation: moderation, chat: chat);
    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
  }

  Future<void> openBlockedTab(
    WidgetTester tester, {
    List<BlockedUser> users = const [],
  }) async {
    moderation = FakeModerationRepository(ownedChannelIds: {'c1'})
      ..blockedUsers = users;
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(
        channels: [makeChannel(1, name: 'Spotted Pisa')],
      ),
      moderation: moderation,
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shield_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloccati'));
    await tester.pumpAndSettle();
  }

  group('dalla chat con un canale', () {
    testWidgets('il proprietario blocca l utente dopo la conferma', (
      tester,
    ) async {
      await openChat(tester);

      await tester.tap(find.byTooltip('Strumenti del proprietario'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blocca utente'));
      await tester.pumpAndSettle();

      expect(find.text('Bloccare @giulia_77?'), findsOneWidget);
      expect(find.textContaining('Gli spot già in attesa'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Blocca'),
        ),
      );
      await tester.pumpAndSettle();

      expect(moderation.blockCalls.single, (chatId: 'cc1', blocked: true));
      expect(find.text('Utente bloccato'), findsOneWidget);
      expect(
        find.textContaining('Hai bloccato @giulia_77'),
        findsOneWidget,
      );
    });

    testWidgets('annullando la conferma non succede niente', (tester) async {
      await openChat(tester);

      await tester.tap(find.byTooltip('Strumenti del proprietario'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blocca utente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(moderation.blockCalls, isEmpty);
      expect(find.textContaining('Hai bloccato'), findsNothing);
    });

    testWidgets('un utente già bloccato si sblocca senza conferma', (
      tester,
    ) async {
      await openChat(tester, blockedChats: {'cc1'});
      expect(find.textContaining('Hai bloccato @giulia_77'), findsOneWidget);

      await tester.tap(find.byTooltip('Strumenti del proprietario'));
      await tester.pumpAndSettle();
      expect(find.text('Blocca utente'), findsNothing);
      await tester.tap(find.text('Sblocca utente'));
      await tester.pumpAndSettle();

      expect(moderation.blockCalls.single, (chatId: 'cc1', blocked: false));
      expect(find.text('Utente sbloccato'), findsOneWidget);
      expect(find.textContaining('Hai bloccato'), findsNothing);
    });

    testWidgets('errore: messaggio e niente cambia', (tester) async {
      await openChat(tester);
      moderation.blockError = const PermissionFailure();

      await tester.tap(find.byTooltip('Strumenti del proprietario'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blocca utente'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Blocca'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Utente bloccato'), findsNothing);
      expect(find.textContaining('Hai bloccato'), findsNothing);
    });

    testWidgets('chi scrive al canale non ha il menu né sa del blocco', (
      tester,
    ) async {
      await openChat(tester, owner: false, blockedChats: {'cc1'});

      expect(find.byTooltip('Strumenti del proprietario'), findsNothing);
      expect(find.textContaining('bloccato'), findsNothing);
    });

    testWidgets('se non si sa se è bloccato, il menu non c è', (tester) async {
      moderation = FakeModerationRepository(ownedChannelIds: {'c1'})
        ..listError = const NetworkFailure();
      chat = FakeChatRepository(chats: [makeChannelChat(1, owner: true)]);
      await pumpApp(tester, moderation: moderation, chat: chat);
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Strumenti del proprietario'), findsNothing);
    });

    testWidgets('le chat degli spot non hanno il menu', (tester) async {
      moderation = FakeModerationRepository(ownedChannelIds: {'c1'});
      chat = FakeChatRepository(chats: [makeChat(1)]);
      await pumpApp(tester, moderation: moderation, chat: chat);
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Strumenti del proprietario'), findsNothing);
    });
  });

  group('scheda Bloccati della Moderazione', () {
    testWidgets('elenca gli utenti bloccati', (tester) async {
      await openBlockedTab(
        tester,
        users: [
          blockedUser(1),
          blockedUser(2, username: 'marco'),
        ],
      );

      expect(find.text('@giulia_77'), findsOneWidget);
      expect(find.text('@marco'), findsOneWidget);
      expect(find.text('Sblocca'), findsNWidgets(2));
    });

    testWidgets('senza utenti bloccati: messaggio', (tester) async {
      await openBlockedTab(tester);

      expect(find.text('Nessun utente bloccato'), findsOneWidget);
      expect(find.textContaining('compaiono qui'), findsOneWidget);
    });

    testWidgets('Sblocca toglie il blocco e l utente dall elenco', (
      tester,
    ) async {
      await openBlockedTab(
        tester,
        users: [
          blockedUser(1),
          blockedUser(2, username: 'marco'),
        ],
      );

      await tester.tap(find.text('Sblocca').first);
      await tester.pumpAndSettle();

      expect(moderation.unblockCalls, ['b1']);
      expect(find.text('Utente sbloccato'), findsOneWidget);
      expect(find.text('@giulia_77'), findsNothing);
      expect(find.text('@marco'), findsOneWidget);
    });

    testWidgets('errore nello sbloccare: messaggio e l utente resta', (
      tester,
    ) async {
      await openBlockedTab(tester, users: [blockedUser(1)]);
      moderation.blockError = const NetworkFailure();

      await tester.tap(find.text('Sblocca'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('@giulia_77'), findsOneWidget);
    });

    testWidgets('errore nel caricare: Riprova', (tester) async {
      moderation = FakeModerationRepository(ownedChannelIds: {'c1'});
      await pumpApp(
        tester,
        channels: FakeChannelsRepository(
          channels: [makeChannel(1, name: 'Spotted Pisa')],
        ),
        moderation: moderation,
      );
      await tester.tap(find.byIcon(Icons.tag_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spotted Pisa'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.shield_rounded));
      await tester.pumpAndSettle();
      moderation.listError = const NetworkFailure();
      await tester.tap(find.text('Bloccati'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      moderation
        ..listError = null
        ..blockedUsers = [blockedUser(1)];
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(find.text('@giulia_77'), findsOneWidget);
    });
  });
}
