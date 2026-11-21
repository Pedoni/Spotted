import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeChatRepository chat;

  Future<void> open(
    WidgetTester tester,
    FakeChatRepository repository, {
    Duration? unreadPollInterval,
  }) async {
    chat = repository;
    await pumpApp(
      tester,
      chat: repository,
      unreadPollInterval: unreadPollInterval,
    );
  }

  /// Il numero sull'icona Chat, o `null` se non c'è.
  Finder badge() => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byType(Badge),
  );

  bool badgeVisible(WidgetTester tester) =>
      tester.widget<Badge>(badge()).isLabelVisible;

  Future<void> openChatsTab(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pumpAndSettle();
  }

  FontWeight? titleWeight(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.fontWeight;

  group('icona Chat nella barra', () {
    testWidgets('mostra quante chat hanno messaggi non letti', (tester) async {
      await open(
        tester,
        FakeChatRepository(
          chats: [
            makeChat(1, unread: true),
            makeChat(2, otherUsername: 'anna', unread: true),
            makeChat(3, otherUsername: 'marco'),
          ],
        ),
      );

      expect(badgeVisible(tester), isTrue);
      expect(find.descendant(of: badge(), matching: find.text('2')), findsOne);
    });

    testWidgets('senza chat non lette non compare', (tester) async {
      await open(tester, FakeChatRepository(chats: [makeChat(1)]));

      expect(badgeVisible(tester), isFalse);
    });

    testWidgets('con tante chat non lette il numero si ferma a 99+', (
      tester,
    ) async {
      await open(
        tester,
        FakeChatRepository(
          chats: [
            for (var i = 1; i <= 120; i++) makeChat(i, unread: true),
          ],
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('se il numero non arriva non si mostra niente', (tester) async {
      await open(
        tester,
        FakeChatRepository(chats: [makeChat(1, unread: true)])
          ..unreadError = const NetworkFailure(),
      );

      expect(badgeVisible(tester), isFalse);
    });

    testWidgets('si aggiorna da solo a intervalli', (tester) async {
      await open(
        tester,
        FakeChatRepository(chats: [makeChat(1)]),
        unreadPollInterval: const Duration(seconds: 30),
      );
      expect(badgeVisible(tester), isFalse);

      // Arriva un messaggio.
      chat.chats = [makeChat(1, unread: true)];
      await tester.pump(const Duration(seconds: 31));
      await tester.pump();

      expect(badgeVisible(tester), isTrue);
      expect(find.descendant(of: badge(), matching: find.text('1')), findsOne);
    });

    testWidgets('quando il numero cambia si ricarica anche l elenco', (
      tester,
    ) async {
      await open(
        tester,
        FakeChatRepository(chats: [makeChat(1)]),
        unreadPollInterval: const Duration(seconds: 30),
      );
      await openChatsTab(tester);
      expect(titleWeight(tester, '@luigi'), isNull);

      chat.chats = [makeChat(1, unread: true)];
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();

      expect(titleWeight(tester, '@luigi'), FontWeight.w700);
    });
  });

  group('elenco delle chat', () {
    testWidgets('la chat non letta è in grassetto, con il puntino', (
      tester,
    ) async {
      await open(
        tester,
        FakeChatRepository(
          chats: [
            makeChat(1, lastMessage: 'Ci sei?', unread: true),
            makeChat(2, otherUsername: 'anna', lastMessage: 'Ok'),
          ],
        ),
      );
      await openChatsTab(tester);

      expect(titleWeight(tester, '@luigi'), FontWeight.w700);
      expect(titleWeight(tester, '@anna'), isNull);
      expect(
        tester.widget<Text>(find.textContaining('Ci sei?')).style?.fontWeight,
        FontWeight.w700,
      );
      expect(
        tester.widget<Text>(find.textContaining('Ok')).style?.fontWeight,
        isNull,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Messaggi non letti',
        ),
        findsOneWidget,
      );
    });

    testWidgets('vale anche per le chat con un canale', (tester) async {
      await open(
        tester,
        FakeChatRepository(
          chats: [makeChannelChat(1, lastMessage: 'Ciao', unread: true)],
        ),
      );
      await openChatsTab(tester);

      expect(titleWeight(tester, 'Spotted Pisa'), FontWeight.w700);
    });

    testWidgets('aprendola si segna come letta e torna normale', (
      tester,
    ) async {
      await open(
        tester,
        FakeChatRepository(
          chats: [makeChat(1, lastMessage: 'Ci sei?', unread: true)],
        ),
      );
      await openChatsTab(tester);

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(chat.readCalls, ['ch1']);

      await tester.tap(find.byTooltip('Indietro'));
      await tester.pumpAndSettle();

      expect(titleWeight(tester, '@luigi'), isNull);
      expect(badgeVisible(tester), isFalse);
    });

    testWidgets('un messaggio che arriva a chat aperta è già letto', (
      tester,
    ) async {
      await open(
        tester,
        FakeChatRepository(
          chats: [makeChat(1, lastMessage: 'Ciao')],
          messages: {
            'ch1': [makeMessage(1)],
          },
        ),
      );
      // Chat aperta con il controllo dei nuovi messaggi attivo.
      await pumpApp(
        tester,
        chat: chat,
        chatPollInterval: const Duration(seconds: 5),
      );
      await openChatsTab(tester);
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      final before = chat.readCalls.length;

      chat.messages['ch1'] = [makeMessage(2, content: 'Nuovo'), makeMessage(1)];
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(find.text('Nuovo'), findsOneWidget);
      expect(chat.readCalls.length, greaterThan(before));
    });

    testWidgets('un messaggio mio non segna niente', (tester) async {
      await open(
        tester,
        FakeChatRepository(
          chats: [makeChat(1, lastMessage: 'Ciao')],
          messages: {
            'ch1': [makeMessage(1)],
          },
        ),
      );
      await pumpApp(
        tester,
        chat: chat,
        chatPollInterval: const Duration(seconds: 5),
      );
      await openChatsTab(tester);
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      final before = chat.readCalls.length;

      chat.messages['ch1'] = [
        makeMessage(2, content: 'Mio', isMine: true),
        makeMessage(1),
      ];
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(find.text('Mio'), findsOneWidget);
      expect(chat.readCalls.length, before);
    });
  });
}
