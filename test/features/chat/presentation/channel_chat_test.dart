import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/chat/domain/entities/chat_message_kind.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeChatRepository chat;

  Future<void> openChats(
    WidgetTester tester,
    FakeChatRepository repository, {
    FakeSpotsRepository? spots,
  }) async {
    chat = repository;
    await pumpApp(tester, chat: repository, spots: spots);
    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pumpAndSettle();
  }

  Future<void> openChat(
    WidgetTester tester,
    FakeChatRepository repository, {
    FakeSpotsRepository? spots,
  }) async {
    await openChats(tester, repository, spots: spots);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
  }

  group('elenco delle chat', () {
    testWidgets('l utente vede il canale, mai il proprietario', (tester) async {
      await openChats(
        tester,
        FakeChatRepository(
          chats: [
            makeChannelChat(
              1,
              lastMessage: 'Ciao!',
              lastMessageIsMine: false,
              lastMessageKind: ChatMessageKind.text,
            ),
          ],
        ),
      );

      expect(find.text('Spotted Pisa'), findsOneWidget);
      expect(find.text('Ciao!'), findsOneWidget);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('il proprietario vede lo username dell utente e il canale', (
      tester,
    ) async {
      await openChats(
        tester,
        FakeChatRepository(
          chats: [
            makeChannelChat(
              1,
              owner: true,
              lastMessage: 'Posso scrivere?',
              lastMessageIsMine: false,
              lastMessageKind: ChatMessageKind.text,
            ),
          ],
        ),
      );

      expect(find.text('@giulia_77'), findsOneWidget);
      expect(find.textContaining('Spotted Pisa'), findsOneWidget);
      expect(find.textContaining('Posso scrivere?'), findsOneWidget);
    });

    testWidgets('un messaggio mio ha il prefisso Tu', (tester) async {
      await openChats(
        tester,
        FakeChatRepository(
          chats: [
            makeChannelChat(
              1,
              lastMessage: 'Grazie',
              lastMessageIsMine: true,
              lastMessageKind: ChatMessageKind.text,
            ),
          ],
        ),
      );

      expect(find.text('Tu: Grazie'), findsOneWidget);
    });

    testWidgets('l ultimo messaggio di sistema si legge come frase', (
      tester,
    ) async {
      await openChats(
        tester,
        FakeChatRepository(
          chats: [
            makeChannelChat(
              1,
              lastMessage: 'Ombrello perso',
              lastMessageIsMine: true,
              lastMessageKind: ChatMessageKind.spotSent,
            ),
            makeChannelChat(
              2,
              lastMessage: 'Ombrello perso',
              lastMessageIsMine: false,
              lastMessageKind: ChatMessageKind.spotApproved,
            ),
            makeChannelChat(
              3,
              owner: true,
              lastMessage: 'Ombrello perso',
              lastMessageIsMine: false,
              lastMessageKind: ChatMessageKind.spotSent,
            ),
          ],
        ),
      );

      expect(find.text('Hai inviato uno spot'), findsOneWidget);
      expect(
        find.text('Spotted Pisa ha pubblicato il tuo spot'),
        findsOneWidget,
      );
      expect(
        find.textContaining('@giulia_77 ha inviato uno spot'),
        findsOneWidget,
      );
      // Il titolo dello spot non fa da anteprima.
      expect(find.text('Ombrello perso'), findsNothing);
    });

    testWidgets(
      'chat degli spot e chat dei canali stanno nello stesso elenco',
      (
        tester,
      ) async {
        await openChats(
          tester,
          FakeChatRepository(chats: [makeChat(1), makeChannelChat(2)]),
        );

        expect(find.text('@luigi'), findsOneWidget);
        expect(find.text('Spotted Pisa'), findsOneWidget);
      },
    );
  });

  group('pagina della chat con un canale', () {
    final messages = {
      'cc1': [
        makeMessage(1, content: 'Grazie del chiarimento', isMine: true),
        makeMessage(
          2,
          content: 'Ombrello perso',
          kind: ChatMessageKind.spotRejected,
          spotId: 's1',
        ),
        makeMessage(
          3,
          content: 'Ombrello perso',
          isMine: true,
          kind: ChatMessageKind.spotSent,
          spotId: 's1',
        ),
      ],
    };

    testWidgets('l utente: nota, messaggi di sistema, niente identità', (
      tester,
    ) async {
      await openChat(
        tester,
        FakeChatRepository(chats: [makeChannelChat(1)], messages: messages),
      );

      expect(find.textContaining('Stai scrivendo al canale'), findsOneWidget);
      expect(find.text('Hai inviato uno spot'), findsOneWidget);
      expect(
        find.text('Spotted Pisa ha rifiutato il tuo spot'),
        findsOneWidget,
      );
      expect(find.text('Grazie del chiarimento'), findsOneWidget);
      // Nessuna rivelazione dell'identità in queste chat.
      expect(find.text('Rivela identità'), findsNothing);
      expect(find.textContaining('Autore del post'), findsNothing);
    });

    testWidgets('il proprietario risponde a nome del canale', (tester) async {
      await openChat(
        tester,
        FakeChatRepository(
          chats: [makeChannelChat(1, owner: true)],
          messages: {
            'cc1': [
              makeMessage(
                1,
                content: 'Ombrello perso',
                isMine: true,
                kind: ChatMessageKind.spotRejected,
                spotId: 's1',
              ),
              makeMessage(
                2,
                content: 'Ombrello perso',
                kind: ChatMessageKind.spotSent,
                spotId: 's1',
              ),
            ],
          },
        ),
      );

      expect(find.text('@giulia_77'), findsOneWidget);
      expect(find.textContaining('Rispondi a nome del canale'), findsOneWidget);
      expect(find.text('Hai rifiutato lo spot'), findsOneWidget);
      expect(find.text('@giulia_77 ha inviato uno spot'), findsOneWidget);
      expect(find.text('Rivela identità'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Manca la foto');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(chat.sendCalls.single, (chatId: 'cc1', content: 'Manca la foto'));
      expect(find.text('Manca la foto'), findsOneWidget);
    });

    testWidgets('toccando il messaggio di sistema si apre lo spot', (
      tester,
    ) async {
      await openChat(
        tester,
        FakeChatRepository(chats: [makeChannelChat(1)], messages: messages),
        spots: FakeSpotsRepository(
          spots: [makeSpot(1, title: 'Ombrello perso')],
        ),
      );

      await tester.tap(find.text('Hai inviato uno spot'));
      await tester.pumpAndSettle();

      expect(find.text('Spot'), findsOneWidget);
      expect(find.text('Ombrello perso'), findsOneWidget);
    });

    testWidgets('se lo spot è stato cancellato il messaggio non è toccabile', (
      tester,
    ) async {
      await openChat(
        tester,
        FakeChatRepository(
          chats: [makeChannelChat(1)],
          messages: {
            'cc1': [
              makeMessage(
                1,
                content: 'Ombrello perso',
                isMine: true,
                kind: ChatMessageKind.spotSent,
              ),
            ],
          },
        ),
      );

      expect(find.text('Hai inviato uno spot'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      await tester.tap(find.text('Hai inviato uno spot'));
      await tester.pumpAndSettle();
      // Resta nella chat.
      expect(find.textContaining('Stai scrivendo al canale'), findsOneWidget);
    });
  });

  group('scrivere al canale dalla sua pagina', () {
    final channel = makeChannel(1, name: 'Spotted Pisa');

    Future<void> openChannel(
      WidgetTester tester, {
      required FakeChatRepository repository,
      bool owner = false,
    }) async {
      chat = repository;
      await pumpApp(
        tester,
        chat: repository,
        channels: FakeChannelsRepository(channels: [channel]),
        moderation: FakeModerationRepository(
          ownedChannelIds: owner ? {'c1'} : const {},
        ),
      );
      await tester.tap(find.byIcon(Icons.tag_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spotted Pisa'));
      await tester.pumpAndSettle();
    }

    testWidgets('un utente apre la chat con il canale', (tester) async {
      await openChannel(
        tester,
        repository: FakeChatRepository(chats: [makeChannelChat(1)]),
      );

      await tester.tap(find.byTooltip('Scrivi al canale'));
      await tester.pumpAndSettle();

      expect(chat.channelChatCalls, ['c1']);
      expect(find.textContaining('Stai scrivendo al canale'), findsOneWidget);
    });

    testWidgets('il proprietario non ha il pulsante', (tester) async {
      await openChannel(
        tester,
        repository: FakeChatRepository(),
        owner: true,
      );

      expect(find.byTooltip('Scrivi al canale'), findsNothing);
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
    });

    testWidgets('se il controllo del proprietario fallisce non compare', (
      tester,
    ) async {
      chat = FakeChatRepository();
      final moderation = FakeModerationRepository()
        ..ownerError = const NetworkFailure();
      await pumpApp(
        tester,
        chat: chat,
        channels: FakeChannelsRepository(channels: [channel]),
        moderation: moderation,
      );
      await tester.tap(find.byIcon(Icons.tag_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spotted Pisa'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Scrivi al canale'), findsNothing);
    });

    testWidgets('errore: messaggio e si resta nel canale', (tester) async {
      final repository = FakeChatRepository()
        ..channelChatError = const NetworkFailure();
      await openChannel(tester, repository: repository);

      await tester.tap(find.byTooltip('Scrivi al canale'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.byTooltip('Scrivi al canale'), findsOneWidget);
    });
  });

  group('limiti e blocco di chi scrive al canale', () {
    Future<void> sendFromChat(
      WidgetTester tester,
      Failure error,
    ) async {
      await openChat(
        tester,
        FakeChatRepository(chats: [makeChannelChat(1)])..sendError = error,
      );
      await tester.enterText(find.byType(TextField), 'Ancora io');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
    }

    testWidgets('troppi messaggi senza risposta: spiega di aspettare', (
      tester,
    ) async {
      await sendFromChat(
        tester,
        const LimitFailure(LimitReason.unansweredMessages),
      );

      expect(
        find.text(
          'Hai già scritto diversi messaggi senza risposta: aspetta che il '
          'canale risponda.',
        ),
        findsOneWidget,
      );
      // Il testo resta nel campo: si potrà rinviare più tardi.
      expect(find.text('Ancora io'), findsOneWidget);
    });

    testWidgets('utente bloccato: messaggio generico, senza dire chi', (
      tester,
    ) async {
      await sendFromChat(tester, const PermissionFailure());

      expect(
        find.text('Non hai i permessi per eseguire questa azione'),
        findsOneWidget,
      );
      expect(find.textContaining('blocc'), findsNothing);
    });
  });
}
