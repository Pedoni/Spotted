import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/moderation/data/datasources/moderation_remote_data_source.dart';
import 'package:spotted/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:spotted/features/moderation/domain/entities/moderation_status.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabase supabase;
  late ModerationRemoteDataSource dataSource;

  Map<String, dynamic> sentBody() =>
      jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;

  void respondWith(Object body, {int status = 200}) {
    supabase = MockSupabase((_) async => jsonResponse(body, status: status));
    dataSource = ModerationRemoteDataSource(supabase.client);
  }

  group('isChannelOwner', () {
    test("chiama l'RPC is_channel_owner", () async {
      respondWith(true);

      final owner = await dataSource.isChannelOwner('c1');

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/is_channel_owner');
      expect(jsonDecode(supabase.lastRequest.body), {'p_channel_id': 'c1'});
      expect(owner, isTrue);
    });

    test('non proprietario: false', () async {
      respondWith(false);

      expect(await dataSource.isChannelOwner('c1'), isFalse);
    });
  });

  group('getSpotAuthor', () {
    test("chiama l'RPC channel_spot_author e legge l'autore", () async {
      respondWith([
        {'author_id': 'u9', 'username': 'giulia_77'},
      ]);

      final author = await dataSource.getSpotAuthor('s1');

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/channel_spot_author',
      );
      expect(jsonDecode(supabase.lastRequest.body), {'p_spot_id': 's1'});
      expect(author.id, 'u9');
      expect(author.username, 'giulia_77');
    });

    test('spot inesistente (nessuna riga): NotFoundFailure', () async {
      respondWith(<Object>[]);

      await expectLater(
        dataSource.getSpotAuthor('s1'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('setSpotStatus', () {
    test("chiama l'RPC set_spot_status con il nome dello stato", () async {
      respondWith(true);

      await dataSource.setSpotStatus('s1', ModerationStatus.hidden);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/set_spot_status');
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_spot_id': 's1',
        'p_status': 'hidden',
      });
    });

    test('invia published e removed con i loro nomi', () async {
      respondWith(true);

      await dataSource.setSpotStatus('s1', ModerationStatus.published);
      expect(sentBody()['p_status'], 'published');

      await dataSource.setSpotStatus('s1', ModerationStatus.removed);
      expect(sentBody()['p_status'], 'removed');
    });

    test(
      'stato invariato o spot inesistente (false): NotFoundFailure',
      () async {
        respondWith(false);

        await expectLater(
          dataSource.setSpotStatus('s1', ModerationStatus.hidden),
          throwsA(isA<NotFoundFailure>()),
        );
      },
    );
  });

  group('setCommentHidden', () {
    test("nascondere chiama set_comment_status con 'hidden'", () async {
      respondWith(true);

      await dataSource.setCommentHidden('k1', hidden: true);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/set_comment_status');
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_comment_id': 'k1',
        'p_status': 'hidden',
      });
    });

    test("ripristinare invia 'published'", () async {
      respondWith(true);

      await dataSource.setCommentHidden('k1', hidden: false);

      expect(sentBody()['p_status'], 'published');
    });

    test('commento inesistente (false): NotFoundFailure', () async {
      respondWith(false);

      await expectLater(
        dataSource.setCommentHidden('k1', hidden: true),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('getHiddenSpots', () {
    test("chiama l'RPC channel_moderation_spots_page", () async {
      respondWith(<Object>[]);

      await dataSource.getHiddenSpots(channelId: 'c1', offset: 20, limit: 20);

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/channel_moderation_spots_page',
      );
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_channel_id': 'c1',
        'p_limit': 20,
        'p_offset': 20,
      });
    });

    test('gli spot letti risultano nascosti e con i conteggi', () async {
      respondWith([spotRow('1', likeCount: 2, commentCount: 1)]);

      final spots = await dataSource.getHiddenSpots(
        channelId: 'c1',
        offset: 0,
        limit: 20,
      );

      expect(spots.single.status, SpotStatus.hidden);
      expect(spots.single.stats.likeCount, 2);
      expect(spots.single.stats.commentCount, 1);
    });
  });

  group('getPendingSpots', () {
    test("chiama l'RPC channel_pending_spots_page", () async {
      respondWith(<Object>[]);

      await dataSource.getPendingSpots(channelId: 'c1', offset: 20, limit: 20);

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/channel_pending_spots_page',
      );
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_channel_id': 'c1',
        'p_limit': 20,
        'p_offset': 20,
      });
    });

    test('gli spot letti risultano in attesa, senza tag', () async {
      respondWith([spotRow('1'), spotRow('2')]);

      final spots = await dataSource.getPendingSpots(
        channelId: 'c1',
        offset: 0,
        limit: 20,
      );

      expect(spots.map((s) => s.id), ['1', '2']);
      expect(spots.every((s) => s.status == SpotStatus.pending), isTrue);
      expect(spots.every((s) => s.tags.isEmpty), isTrue);
    });
  });

  group('getPendingSpotsCount', () {
    test(
      "chiama l'RPC channel_pending_spots_count e legge il numero",
      () async {
        respondWith(3);

        final count = await dataSource.getPendingSpotsCount('c1');

        expect(
          supabase.lastRequest.url.path,
          '/rest/v1/rpc/channel_pending_spots_count',
        );
        expect(jsonDecode(supabase.lastRequest.body), {'p_channel_id': 'c1'});
        expect(count, 3);
      },
    );
  });

  group('approveSpot', () {
    test("chiama l'RPC approve_spot con i tag", () async {
      respondWith(true);

      await dataSource.approveSpot('s1', ['crush', 'meme']);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/approve_spot');
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_spot_id': 's1',
        'p_tags': ['crush', 'meme'],
      });
    });

    test('spot inesistente o non in attesa (false): NotFoundFailure', () async {
      respondWith(false);

      await expectLater(
        dataSource.approveSpot('s1', ['crush']),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('rejectSpot', () {
    test("chiama l'RPC reject_spot", () async {
      respondWith(true);

      await dataSource.rejectSpot('s1');

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/reject_spot');
      expect(jsonDecode(supabase.lastRequest.body), {'p_spot_id': 's1'});
    });

    test('spot inesistente o non in attesa (false): NotFoundFailure', () async {
      respondWith(false);

      await expectLater(
        dataSource.rejectSpot('s1'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('blocco degli utenti', () {
    test("setChatUserBlocked chiama l'RPC set_chat_user_blocked", () async {
      respondWith(true);

      await dataSource.setChatUserBlocked('cc1', blocked: true);

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/set_chat_user_blocked',
      );
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_chat_id': 'cc1',
        'p_blocked': true,
      });
    });

    test('sbloccare manda blocked false', () async {
      respondWith(true);

      await dataSource.setChatUserBlocked('cc1', blocked: false);

      expect(jsonDecode(supabase.lastRequest.body), {
        'p_chat_id': 'cc1',
        'p_blocked': false,
      });
    });

    test('chat inesistente o già in quello stato (false): NotFoundFailure', () {
      respondWith(false);

      expect(
        dataSource.setChatUserBlocked('cc1', blocked: true),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test("isChatUserBlocked chiama l'RPC is_chat_user_blocked", () async {
      respondWith(true);

      final blocked = await dataSource.isChatUserBlocked('cc1');

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/is_chat_user_blocked',
      );
      expect(jsonDecode(supabase.lastRequest.body), {'p_chat_id': 'cc1'});
      expect(blocked, isTrue);
    });

    test("getBlockedUsers chiama l'RPC channel_blocked_users", () async {
      respondWith([
        {
          'id': 'b1',
          'username': 'giulia_77',
          'created_at': '2026-01-01T10:00:00+00:00',
        },
      ]);

      final users = await dataSource.getBlockedUsers(
        channelId: 'c1',
        offset: 20,
        limit: 20,
      );

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/channel_blocked_users',
      );
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_channel_id': 'c1',
        'p_limit': 20,
        'p_offset': 20,
      });
      // L'id è quello del blocco, mai quello dell'utente.
      expect(users.single.id, 'b1');
      expect(users.single.username, 'giulia_77');
      expect(users.single.createdAt, DateTime.utc(2026, 1, 1, 10));
    });

    test("unblockChannelUser chiama l'RPC unblock_channel_user", () async {
      respondWith(true);

      await dataSource.unblockChannelUser('b1');

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/unblock_channel_user',
      );
      expect(jsonDecode(supabase.lastRequest.body), {'p_block_id': 'b1'});
    });

    test('blocco inesistente (false): NotFoundFailure', () {
      respondWith(false);

      expect(
        dataSource.unblockChannelUser('b1'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('non proprietario (42501): PermissionFailure', () async {
      supabase = MockSupabase((_) async => postgrestError('42501', 'no'));
      final repository = ModerationRepositoryImpl(
        ModerationRemoteDataSource(supabase.client),
      );

      await expectLater(
        repository.setChatUserBlocked('cc1', blocked: true),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repository.getBlockedUsers(channelId: 'c1', offset: 0, limit: 20),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repository.unblockChannelUser('b1'),
        throwsA(isA<PermissionFailure>()),
      );
    });
  });

  group('errori (repository)', () {
    late ModerationRepositoryImpl repository;

    void respondError(String code) {
      supabase = MockSupabase((_) async => postgrestError(code, 'errore'));
      repository = ModerationRepositoryImpl(
        ModerationRemoteDataSource(supabase.client),
      );
    }

    test('non proprietario (42501): PermissionFailure', () async {
      respondError('42501');

      await expectLater(
        repository.getSpotAuthor('s1'),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repository.setSpotStatus('s1', ModerationStatus.hidden),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repository.setCommentHidden('k1', hidden: true),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repository.getHiddenSpots(channelId: 'c1', offset: 0, limit: 20),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('approvare e rifiutare: non proprietario (42501)', () async {
      respondError('42501');

      await expectLater(
        repository.approveSpot('s1', ['crush']),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repository.rejectSpot('s1'),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repository.getPendingSpots(channelId: 'c1', offset: 0, limit: 20),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repository.getPendingSpotsCount('c1'),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('approvare con tag non validi (23514): ValidationFailure', () async {
      respondError('23514');

      await expectLater(
        repository.approveSpot('s1', ['inventato']),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('stato non valido (23514): ValidationFailure', () async {
      respondError('23514');

      await expectLater(
        repository.setSpotStatus('s1', ModerationStatus.hidden),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('risposta con tipi inattesi: UnknownFailure', () async {
      respondWith([
        {'author_id': 1},
      ]);
      repository = ModerationRepositoryImpl(dataSource);

      await expectLater(
        repository.getSpotAuthor('s1'),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });
}
