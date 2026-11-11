import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:spotted/features/chat/data/repositories/chat_repository_impl.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabase supabase;
  late ChatRemoteDataSource dataSource;

  Map<String, dynamic> sentBody() =>
      jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;

  void respondWith(Object? body, {int status = 200}) {
    supabase = MockSupabase((_) async => jsonResponse(body, status: status));
    dataSource = ChatRemoteDataSource(supabase.client);
  }

  group('isSpotAuthor', () {
    test("chiama l'RPC is_spot_author", () async {
      respondWith(true);

      final author = await dataSource.isSpotAuthor('s1');

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/is_spot_author');
      expect(sentBody(), {'p_spot_id': 's1'});
      expect(author, isTrue);
    });
  });

  group('startChat', () {
    test("chiama l'RPC start_chat e restituisce l'id della chat", () async {
      respondWith('ch1');

      final chatId = await dataSource.startChat('k1');

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/start_chat');
      expect(sentBody(), {'p_comment_id': 'k1'});
      expect(chatId, 'ch1');
    });

    test('commento inesistente (null): NotFoundFailure', () async {
      respondWith(null);

      await expectLater(
        dataSource.startChat('k1'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('revealIdentity', () {
    test("chiama l'RPC reveal_identity", () async {
      respondWith(true);

      await dataSource.revealIdentity('ch1');

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/reveal_identity');
      expect(sentBody(), {'p_chat_id': 'ch1'});
    });

    test('chat inesistente o già rivelata (false): NotFoundFailure', () async {
      respondWith(false);

      await expectLater(
        dataSource.revealIdentity('ch1'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('getChats', () {
    test("chiama l'RPC my_chats_page con paginazione", () async {
      respondWith(<Object>[]);

      await dataSource.getChats(offset: 20, limit: 20);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/my_chats_page');
      expect(sentBody(), {'p_limit': 20, 'p_offset': 20});
    });

    test("l'autore vede lo username del commentatore", () async {
      respondWith([
        chatRow(
          '1',
          lastMessage: 'Ciao',
          lastMessageIsMine: true,
        ),
      ]);

      final chats = await dataSource.getChats(offset: 0, limit: 20);

      expect(chats.single.iAmAuthor, isTrue);
      expect(chats.single.otherUsername, 'luigi');
      expect(chats.single.spotTitle, 'Ombrello perso');
      expect(chats.single.channelName, 'Spotted Pisa');
      expect(chats.single.lastMessage, 'Ciao');
      expect(chats.single.lastMessageIsMine, isTrue);
      expect(chats.single.lastMessageAt, DateTime.utc(2026, 1, 1, 11));
      expect(chats.single.createdAt, DateTime.utc(2026, 1, 1, 10));
    });

    test('il commentatore non vede l autore finché non è rivelato', () async {
      respondWith([
        chatRow('1', iAmAuthor: false, otherUsername: null),
        chatRow(
          '2',
          iAmAuthor: false,
          otherUsername: 'giulia_77',
          identityRevealed: true,
        ),
      ]);

      final chats = await dataSource.getChats(offset: 0, limit: 20);

      expect(chats[0].iAmAuthor, isFalse);
      expect(chats[0].otherUsername, isNull);
      expect(chats[0].identityRevealed, isFalse);
      expect(chats[1].otherUsername, 'giulia_77');
      expect(chats[1].identityRevealed, isTrue);
    });

    test('una chat senza messaggi non ha ultimo messaggio', () async {
      respondWith([chatRow('1')]);

      final chats = await dataSource.getChats(offset: 0, limit: 20);

      expect(chats.single.lastMessage, isNull);
      expect(chats.single.lastMessageAt, isNull);
      expect(chats.single.lastMessageIsMine, isNull);
    });
  });

  group('getChat', () {
    test("chiama l'RPC chat_detail", () async {
      respondWith([chatRow('1')]);

      final chat = await dataSource.getChat('1');

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/chat_detail');
      expect(sentBody(), {'p_chat_id': '1'});
      expect(chat.id, '1');
    });

    test('nessuna riga (non esiste o non è sua): NotFoundFailure', () async {
      respondWith(<Object>[]);

      await expectLater(
        dataSource.getChat('1'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('getMessages', () {
    test("chiama l'RPC chat_messages con chat e paginazione", () async {
      respondWith(<Object>[]);

      await dataSource.getMessages(chatId: 'ch1', offset: 20, limit: 20);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/chat_messages');
      expect(sentBody(), {
        'p_chat_id': 'ch1',
        'p_limit': 20,
        'p_offset': 20,
      });
    });

    test('legge i messaggi con "è mio"', () async {
      respondWith([
        messageRow('1', isMine: true),
        messageRow('2', content: 'Ciao'),
      ]);

      final messages = await dataSource.getMessages(
        chatId: 'ch1',
        offset: 0,
        limit: 20,
      );

      expect(messages, hasLength(2));
      expect(messages[0].isMine, isTrue);
      expect(messages[1].isMine, isFalse);
      expect(messages[1].content, 'Ciao');
      expect(messages[1].createdAt, DateTime.utc(2026, 1, 1, 10));
    });
  });

  group('sendMessage', () {
    test("chiama l'RPC send_message e restituisce il messaggio", () async {
      respondWith([messageRow('9', content: 'Ciao', isMine: true)]);

      final message = await dataSource.sendMessage(
        chatId: 'ch1',
        content: 'Ciao',
      );

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/send_message');
      expect(sentBody(), {'p_chat_id': 'ch1', 'p_content': 'Ciao'});
      expect(message.id, '9');
      expect(message.isMine, isTrue);
    });

    test('chat non scrivibile (nessuna riga): NotFoundFailure', () async {
      respondWith(<Object>[]);

      await expectLater(
        dataSource.sendMessage(chatId: 'ch1', content: 'Ciao'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('errori (repository)', () {
    late ChatRepositoryImpl repository;

    void respondError(String code) {
      supabase = MockSupabase((_) async => postgrestError(code, 'errore'));
      repository = ChatRepositoryImpl(ChatRemoteDataSource(supabase.client));
    }

    test('non è l autore dello spot (42501): PermissionFailure', () async {
      respondError('42501');

      await expectLater(
        repository.startChat('k1'),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repository.revealIdentity('ch1'),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test(
      'chat con sé stessi o testo non valido (23514): ValidationFailure',
      () async {
        respondError('23514');

        await expectLater(
          repository.startChat('k1'),
          throwsA(isA<ValidationFailure>()),
        );
        await expectLater(
          repository.sendMessage(chatId: 'ch1', content: 'x'),
          throwsA(isA<ValidationFailure>()),
        );
      },
    );

    test('risposta con tipi inattesi: UnknownFailure', () async {
      respondWith([
        {'id': 1},
      ]);
      repository = ChatRepositoryImpl(dataSource);

      await expectLater(
        repository.getChats(offset: 0, limit: 20),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });
}
