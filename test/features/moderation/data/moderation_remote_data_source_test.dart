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
