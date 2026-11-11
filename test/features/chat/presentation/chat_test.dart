import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/comments/presentation/widgets/comment_tile.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeChatRepository chat;

  /// Il pulsante "Rivela identità" della conferma (c'è anche quello del
  /// banner).
  final confirmReveal = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextButton, 'Rivela identità'),
  );

  /// Apre "Le mie chat" dal Profilo.
  Future<void> openChats(
    WidgetTester tester,
    FakeChatRepository repository, {
    Duration? pollInterval,
  }) async {
    chat = repository;
    await pumpApp(tester, chat: repository, chatPollInterval: pollInterval);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le mie chat'));
    await tester.pumpAndSettle();
  }

  /// Apre "Le mie chat" e la prima chat.
  Future<void> openChat(
    WidgetTester tester,
    FakeChatRepository repository, {
    Duration? pollInterval,
  }) async {
    await openChats(tester, repository, pollInterval: pollInterval);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
  }

  group('Le mie chat', () {
    testWidgets('senza chat: messaggio', (tester) async {
      await openChats(tester, FakeChatRepository());

      expect(find.text('Ancora nessuna chat'), findsOneWidget);
    });

    testWidgets("l'autore vede lo username di chi ha commentato", (
      tester,
    ) async {
      await openChats(
        tester,
        FakeChatRepository(
          chats: [
            makeChat(1, lastMessage: 'Ciao', lastMessageIsMine: true),
            makeChat(2, otherUsername: 'anna'),
          ],
        ),
      );

      expect(find.text('@luigi'), findsOneWidget);
      expect(find.text('@anna'), findsOneWidget);
      expect(find.textContaining('Ombrello perso'), findsNWidgets(2));
      // Un ultimo messaggio mio ha il prefisso; una chat vuota lo dice.
      expect(find.textContaining('Tu: Ciao'), findsOneWidget);
      expect(find.textContaining('Nessun messaggio'), findsOneWidget);
    });

    testWidgets('il commentatore vede l autore come anonimo', (tester) async {
      await openChats(
        tester,
        FakeChatRepository(
          chats: [
            makeChat(
              1,
              iAmAuthor: false,
              otherUsername: null,
              lastMessage: 'Ciao, ho trovato il tuo ombrello',
              lastMessageIsMine: false,
            ),
          ],
        ),
      );

      expect(find.text('Autore del post'), findsOneWidget);
      expect(
        find.textContaining('Ciao, ho trovato il tuo ombrello'),
        findsOneWidget,
      );
      expect(find.textContaining('Tu:'), findsNothing);
    });

    testWidgets("a identità rivelata il commentatore vede l'autore", (
      tester,
    ) async {
      await openChats(
        tester,
        FakeChatRepository(
          chats: [
            makeChat(
              1,
              iAmAuthor: false,
              otherUsername: 'giulia_77',
              identityRevealed: true,
              lastMessage: 'Sono io',
            ),
          ],
        ),
      );

      expect(find.text('@giulia_77'), findsOneWidget);
      expect(find.text('Autore del post'), findsNothing);
    });

    testWidgets('errore: messaggio e Riprova', (tester) async {
      final repository = FakeChatRepository(chats: [makeChat(1)])
        ..listError = const NetworkFailure();
      await openChats(tester, repository);

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      repository.listError = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(find.text('@luigi'), findsOneWidget);
    });
  });

  group('una chat', () {
    testWidgets('mostra lo spot e i messaggi', (tester) async {
      await openChat(
        tester,
        FakeChatRepository(
          chats: [makeChat(1)],
          messages: {
            'ch1': [
              makeMessage(1, content: 'Grazie!', isMine: true),
              makeMessage(2, content: 'Ho il tuo ombrello'),
            ],
          },
        ),
      );

      expect(find.text('@luigi'), findsWidgets);
      expect(find.text('Ombrello perso'), findsOneWidget);
      expect(find.text('Spotted Pisa'), findsOneWidget);
      expect(find.text('Grazie!'), findsOneWidget);
      expect(find.text('Ho il tuo ombrello'), findsOneWidget);
    });

    testWidgets('senza messaggi: invito a scrivere il primo', (tester) async {
      await openChat(tester, FakeChatRepository(chats: [makeChat(1)]));

      expect(find.text('Nessun messaggio. Scrivi il primo!'), findsOneWidget);
    });

    testWidgets('errore nel caricare i messaggi: messaggio e Riprova', (
      tester,
    ) async {
      final repository = FakeChatRepository(
        chats: [makeChat(1)],
        messages: {
          'ch1': [makeMessage(1)],
        },
      )..messagesError = const NetworkFailure();
      await openChat(tester, repository);

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      repository.messagesError = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      expect(find.text('Messaggio 1'), findsOneWidget);
    });

    testWidgets('invia un messaggio: compare e il campo si svuota', (
      tester,
    ) async {
      await openChat(tester, FakeChatRepository(chats: [makeChat(1)]));

      await tester.enterText(find.byType(TextField), '  Ciao  ');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(chat.sendCalls.single, (chatId: 'ch1', content: 'Ciao'));
      expect(find.text('Ciao'), findsOneWidget);
      expect(find.text('Nessun messaggio. Scrivi il primo!'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('un messaggio vuoto non viene inviato', (tester) async {
      await openChat(tester, FakeChatRepository(chats: [makeChat(1)]));

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(chat.sendCalls, isEmpty);
    });

    testWidgets('errore nell invio: messaggio e il testo resta', (
      tester,
    ) async {
      final repository = FakeChatRepository(chats: [makeChat(1)])
        ..sendError = const NetworkFailure();
      await openChat(tester, repository);

      await tester.enterText(find.byType(TextField), 'Ciao');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Ciao',
      );
    });

    testWidgets('i nuovi messaggi arrivano col polling', (tester) async {
      final repository = FakeChatRepository(
        chats: [makeChat(1)],
        messages: {
          'ch1': [makeMessage(1, content: 'Primo')],
        },
      );
      await openChat(
        tester,
        repository,
        pollInterval: const Duration(seconds: 5),
      );
      expect(find.text('Primo'), findsOneWidget);
      expect(find.text('Risposta'), findsNothing);

      repository.messages['ch1'] = [
        makeMessage(0, content: 'Risposta'),
        makeMessage(1, content: 'Primo'),
      ];
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('Risposta'), findsOneWidget);
      expect(find.text('Primo'), findsOneWidget);
    });

    testWidgets('toccando lo spot si apre il dettaglio', (tester) async {
      await openChat(tester, FakeChatRepository(chats: [makeChat(1)]));

      await tester.tap(find.text('Ombrello perso'));
      await tester.pumpAndSettle();

      expect(find.text('Spot'), findsOneWidget);
    });
  });

  group('identità', () {
    testWidgets("l'autore la rivela dopo la conferma", (tester) async {
      await openChat(
        tester,
        FakeChatRepository(
          chats: [makeChat(1)],
          messages: {
            'ch1': [makeMessage(1)],
          },
        ),
      );
      expect(
        find.text("Non sanno chi sei: sei l'autore anonimo dello spot"),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Rivela identità'));
      await tester.pumpAndSettle();
      expect(find.text('Rivelare la tua identità?'), findsOneWidget);
      expect(
        find.text(
          "@luigi vedrà il tuo username. L'operazione non si può annullare.",
        ),
        findsOneWidget,
      );
      await tester.tap(confirmReveal);
      await tester.pumpAndSettle();

      expect(chat.revealCalls, ['ch1']);
      expect(find.text('Identità rivelata'), findsOneWidget);
      expect(find.text('Hai rivelato la tua identità'), findsOneWidget);
      // Non si può annullare: il pulsante sparisce.
      expect(find.text('Rivela identità'), findsNothing);
    });

    testWidgets('annullando la conferma non rivela niente', (tester) async {
      await openChat(tester, FakeChatRepository(chats: [makeChat(1)]));

      await tester.tap(find.widgetWithText(TextButton, 'Rivela identità'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(chat.revealCalls, isEmpty);
      expect(find.text('Rivela identità'), findsOneWidget);
    });

    testWidgets('errore nel rivelare: messaggio e resta anonimo', (
      tester,
    ) async {
      final repository = FakeChatRepository(chats: [makeChat(1)])
        ..revealError = const NetworkFailure();
      await openChat(tester, repository);

      await tester.tap(find.widgetWithText(TextButton, 'Rivela identità'));
      await tester.pumpAndSettle();
      await tester.tap(confirmReveal);
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('Hai rivelato la tua identità'), findsNothing);
      expect(find.text('Rivela identità'), findsOneWidget);
    });

    testWidgets("il commentatore vede l'autore come anonimo, senza pulsante", (
      tester,
    ) async {
      await openChat(
        tester,
        FakeChatRepository(
          chats: [makeChat(1, iAmAuthor: false, otherUsername: null)],
          messages: {
            'ch1': [makeMessage(1, content: 'Ho il tuo ombrello')],
          },
        ),
      );

      expect(find.text('Autore del post'), findsOneWidget);
      expect(find.text("L'autore dello spot è anonimo"), findsOneWidget);
      expect(find.text('Rivela identità'), findsNothing);
    });

    testWidgets("a identità rivelata il commentatore vede l'autore", (
      tester,
    ) async {
      await openChat(
        tester,
        FakeChatRepository(
          chats: [
            makeChat(
              1,
              iAmAuthor: false,
              otherUsername: 'giulia_77',
              identityRevealed: true,
            ),
          ],
        ),
      );

      expect(find.text('@giulia_77'), findsOneWidget);
      expect(find.text("L'autore dello spot è anonimo"), findsNothing);
      expect(find.text('Rivela identità'), findsNothing);
    });
  });

  group('avviare una chat dai commenti', () {
    final channel = makeChannel(1, name: 'Spotted Pisa');

    Future<void> openSpot(
      WidgetTester tester, {
      required FakeChatRepository repository,
    }) async {
      // Abbastanza alta da costruire tutti i commenti.
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      chat = repository;
      await pumpApp(
        tester,
        channels: FakeChannelsRepository(channels: [channel]),
        spots: FakeSpotsRepository(
          spots: [makeSpot(1, title: 'Ombrello perso')],
        ),
        comments: FakeCommentsRepository(
          comments: [
            makeComment(1),
            makeComment(2, isMine: true, isSpotAuthor: true),
            makeComment(3, authorUsername: 'anna'),
          ],
        ),
        chat: repository,
      );
      await tester.tap(find.byIcon(Icons.tag_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spotted Pisa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ombrello perso'));
      await tester.pumpAndSettle();
    }

    final chatButtons = find.descendant(
      of: find.byType(CommentTile),
      matching: find.byTooltip('Chatta'),
    );

    testWidgets("l'autore dello spot chatta con chi ha commentato", (
      tester,
    ) async {
      await openSpot(
        tester,
        repository: FakeChatRepository(
          chats: [makeChat(1)],
          spotAuthor: true,
        ),
      );

      // Due commenti di altri; il suo non ha il pulsante.
      expect(chatButtons, findsNWidgets(2));

      await tester.tap(chatButtons.first);
      await tester.pumpAndSettle();

      expect(chat.startCalls.single, 'k1');
      // Si apre la chat.
      expect(find.text('Nessun messaggio. Scrivi il primo!'), findsOneWidget);
      expect(find.text('@luigi'), findsWidgets);
    });

    testWidgets('chi non è l autore dello spot non ha il pulsante', (
      tester,
    ) async {
      await openSpot(tester, repository: FakeChatRepository());

      expect(chatButtons, findsNothing);
    });

    testWidgets('se non si sa se è l autore il pulsante resta nascosto', (
      tester,
    ) async {
      await openSpot(
        tester,
        repository: FakeChatRepository(spotAuthor: true)
          ..authorError = const NetworkFailure(),
      );

      expect(chatButtons, findsNothing);
    });

    testWidgets('errore nell avvio: messaggio e resta sullo spot', (
      tester,
    ) async {
      await openSpot(
        tester,
        repository: FakeChatRepository(spotAuthor: true)
          ..startError = const PermissionFailure(),
      );

      await tester.tap(chatButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Nessun messaggio. Scrivi il primo!'), findsNothing);
      expect(find.text('Ombrello perso'), findsOneWidget);
    });
  });
}
