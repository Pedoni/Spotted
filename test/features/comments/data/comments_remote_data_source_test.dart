import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/comments/data/datasources/comments_remote_data_source.dart';
import 'package:spotted/features/comments/data/repositories/comments_repository_impl.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabase supabase;
  late CommentsRemoteDataSource dataSource;

  void respondWith(Object body, {int status = 200}) {
    supabase = MockSupabase((_) async => jsonResponse(body, status: status));
    dataSource = CommentsRemoteDataSource(supabase.client);
  }

  group('getSpotComments', () {
    test("chiama l'RPC spot_comments con spot e paginazione", () async {
      respondWith(<Object>[]);

      await dataSource.getSpotComments(spotId: 's1', offset: 20, limit: 20);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/spot_comments');
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_spot_id': 's1',
        'p_limit': 20,
        'p_offset': 20,
      });
    });

    test('legge i commenti: username, autore del post, like', () async {
      respondWith([
        commentRow('1', likeCount: 2, isMine: true),
        commentRow('2', isSpotAuthor: true, likedByMe: true),
      ]);

      final comments = await dataSource.getSpotComments(
        spotId: 's1',
        offset: 0,
        limit: 20,
      );

      expect(comments, hasLength(2));
      expect(comments[0].authorUsername, 'luigi');
      expect(comments[0].isSpotAuthor, isFalse);
      expect(comments[0].isMine, isTrue);
      expect(comments[0].likeCount, 2);
      expect(comments[0].createdAt, DateTime.utc(2026, 1, 1, 10));
      // L'autore dello spot non ha nome.
      expect(comments[1].authorUsername, isNull);
      expect(comments[1].isSpotAuthor, isTrue);
      expect(comments[1].likedByMe, isTrue);
    });
  });

  group('addComment', () {
    test("chiama l'RPC add_comment e restituisce il commento", () async {
      respondWith([commentRow('9', content: 'Ciao', isMine: true)]);

      final comment = await dataSource.addComment(
        spotId: 's1',
        content: 'Ciao',
      );

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/add_comment');
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_spot_id': 's1',
        'p_content': 'Ciao',
      });
      expect(comment.id, '9');
      expect(comment.isMine, isTrue);
    });

    test('spot inesistente (nessuna riga): NotFoundFailure', () async {
      respondWith(<Object>[]);

      await expectLater(
        dataSource.addComment(spotId: 's1', content: 'Ciao'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('deleteComment', () {
    test("chiama l'RPC delete_comment", () async {
      respondWith(true);

      await dataSource.deleteComment('k1');

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/delete_comment');
      expect(jsonDecode(supabase.lastRequest.body), {'p_comment_id': 'k1'});
    });

    test('non esiste o non è suo (false): NotFoundFailure', () async {
      respondWith(false);

      await expectLater(
        dataSource.deleteComment('k1'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('setCommentLiked', () {
    test("chiama l'RPC set_comment_liked", () async {
      respondWith(<String, dynamic>{});

      await dataSource.setCommentLiked('k1', liked: false);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/set_comment_liked');
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_comment_id': 'k1',
        'p_liked': false,
      });
    });
  });

  group('errori (repository)', () {
    late CommentsRepositoryImpl repository;

    void respondError(String code) {
      supabase = MockSupabase((_) async => postgrestError(code, 'errore'));
      repository = CommentsRepositoryImpl(
        CommentsRemoteDataSource(supabase.client),
      );
    }

    test('check_violation (testo troppo lungo): ValidationFailure', () async {
      respondError('23514');

      await expectLater(
        repository.addComment(spotId: 's1', content: 'x'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('permesso negato: PermissionFailure', () async {
      respondError('42501');

      await expectLater(
        repository.getSpotComments(spotId: 's1', offset: 0, limit: 20),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('risposta con tipi inattesi: UnknownFailure', () async {
      respondWith([
        {'id': 1},
      ]);
      repository = CommentsRepositoryImpl(dataSource);

      await expectLater(
        repository.getSpotComments(spotId: 's1', offset: 0, limit: 20),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });
}
