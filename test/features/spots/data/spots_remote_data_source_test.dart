import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/data/datasources/spots_remote_data_source.dart';
import 'package:spotted/features/spots/data/models/spot_dto.dart';
import 'package:spotted/features/spots/data/repositories/spots_repository_impl.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabase supabase;
  late SpotsRemoteDataSource dataSource;

  void respondWith(
    Object body, {
    int status = 200,
    String? Function()? userId,
  }) {
    supabase = MockSupabase((_) async => jsonResponse(body, status: status));
    dataSource = SpotsRemoteDataSource(
      supabase.client,
      currentUserId: userId ?? () => 'user-1',
    );
  }

  group('getChannelSpots', () {
    test("chiama l'RPC channel_spots_page con canale e paginazione", () async {
      respondWith(<Object>[]);

      await dataSource.getChannelSpots(channelId: 'c1', offset: 40, limit: 20);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/channel_spots_page');
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_channel_id': 'c1',
        'p_limit': 20,
        'p_offset': 40,
      });
    });

    test('legge gli spot con i conteggi', () async {
      respondWith([
        spotRow(
          '1',
          title: 'Ciao',
          content: 'Mondo',
          likeCount: 3,
          commentCount: 2,
          likedByMe: true,
        ),
      ]);

      final spots = await dataSource.getChannelSpots(
        channelId: 'c1',
        offset: 0,
        limit: 20,
      );

      expect(spots.single.title, 'Ciao');
      expect(spots.single.content, 'Mondo');
      expect(spots.single.channelId, 'c1');
      expect(spots.single.createdAt, DateTime.utc(2026, 1, 1, 10));
      expect(
        spots.single.stats,
        const SpotStats(likeCount: 3, commentCount: 2, likedByMe: true),
      );
    });
  });

  group('getSpot', () {
    test("chiama l'RPC spot_detail", () async {
      respondWith([spotRow('7', likeCount: 1, commentCount: 0)]);

      final spot = await dataSource.getSpot('7');

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/spot_detail');
      expect(jsonDecode(supabase.lastRequest.body), {'p_spot_id': '7'});
      expect(spot.id, '7');
      expect(spot.stats.likeCount, 1);
    });

    test('spot inesistente (nessuna riga): NotFoundFailure', () async {
      respondWith(<Object>[]);

      await expectLater(
        dataSource.getSpot('7'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('setSpotLiked', () {
    test("chiama l'RPC set_spot_liked", () async {
      respondWith(<String, dynamic>{});

      await dataSource.setSpotLiked('s1', liked: true);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/set_spot_liked');
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_spot_id': 's1',
        'p_liked': true,
      });
    });
  });

  group('getMySpots', () {
    test("chiama l'RPC my_spots_page e legge il canale", () async {
      respondWith([
        {
          ...spotRow('1'),
          'channel_name': 'Spotted Pisa',
          'channel_slug': 'spotted-pisa',
          'like_count': 5,
          'comment_count': 1,
          'liked_by_me': false,
        },
      ]);

      final spots = await dataSource.getMySpots(offset: 20, limit: 20);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/my_spots_page');
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_limit': 20,
        'p_offset': 20,
      });
      expect(spots.single.channelName, 'Spotted Pisa');
      expect(spots.single.channelSlug, 'spotted-pisa');
      expect(spots.single.spot.title, 'Spot 1');
      expect(spots.single.spot.stats.likeCount, 5);
    });
  });

  group('getFollowedSpots', () {
    test(
      "chiama l'RPC followed_spots_page e legge canale e conteggi",
      () async {
        respondWith([
          {
            ...spotRow('1', likeCount: 2, commentCount: 3, likedByMe: true),
            'channel_name': 'Spotted Pisa',
            'channel_slug': 'spotted-pisa',
          },
        ]);

        final spots = await dataSource.getFollowedSpots(offset: 40, limit: 20);

        expect(
          supabase.lastRequest.url.path,
          '/rest/v1/rpc/followed_spots_page',
        );
        expect(jsonDecode(supabase.lastRequest.body), {
          'p_limit': 20,
          'p_offset': 40,
        });
        expect(spots.single.channelSlug, 'spotted-pisa');
        expect(spots.single.spot.stats.commentCount, 3);
        expect(spots.single.spot.stats.likedByMe, isTrue);
      },
    );
  });

  group('createSpot', () {
    test('invia solo le colonne scrivibili e non chiede author_id', () async {
      respondWith(spotRow('9', title: 'Titolo', content: 'Testo'));

      final spot = await dataSource.createSpot(
        channelId: 'c1',
        title: 'Titolo',
        content: 'Testo',
      );

      expect(supabase.lastRequest.method, 'POST');
      expect(jsonDecode(supabase.lastRequest.body), {
        'author_id': 'user-1',
        'channel_id': 'c1',
        'title': 'Titolo',
        'content': 'Testo',
      });
      final query = supabase.lastRequest.url.queryParameters;
      expect(query['select'], spotColumns.replaceAll(' ', ''));
      expect(spot.id, '9');
      expect(spot.stats, const SpotStats());
    });

    test('senza sessione: AuthFailure, nessuna richiesta', () async {
      respondWith(spotRow('9'), userId: () => null);

      await expectLater(
        dataSource.createSpot(channelId: 'c1', title: 't', content: 'c'),
        throwsA(isA<AuthFailure>()),
      );
      expect(supabase.requests, isEmpty);
    });
  });

  group('deleteSpot', () {
    test('cancella per id', () async {
      respondWith([
        {'id': 's1'},
      ]);

      await dataSource.deleteSpot('s1');

      expect(supabase.lastRequest.method, 'DELETE');
      expect(supabase.lastRequest.url.queryParameters['id'], 'eq.s1');
    });

    test('nessuna riga cancellata: NotFoundFailure', () async {
      respondWith(<Object>[]);

      await expectLater(
        dataSource.deleteSpot('s1'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('errori (repository)', () {
    late SpotsRepositoryImpl repository;

    void respondError(String code, String message) {
      supabase = MockSupabase(
        (_) async => postgrestError(code, message),
      );
      repository = SpotsRepositoryImpl(
        SpotsRemoteDataSource(supabase.client, currentUserId: () => 'u'),
      );
    }

    test('check_violation diventa ValidationFailure', () async {
      respondError('23514', 'violates check constraint "spots_title_length"');

      await expectLater(
        repository.createSpot(channelId: 'c1', title: 't', content: 'c'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('RLS negata diventa PermissionFailure', () async {
      respondError('42501', 'new row violates row-level security policy');

      await expectLater(
        repository.createSpot(channelId: 'c1', title: 't', content: 'c'),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('rete assente diventa NetworkFailure', () async {
      supabase = MockSupabase((_) async => throw TimeoutException('lento'));
      repository = SpotsRepositoryImpl(
        SpotsRemoteDataSource(supabase.client, currentUserId: () => 'u'),
      );

      await expectLater(
        repository.getChannelSpots(channelId: 'c1', offset: 0, limit: 20),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('status', () {
    test('getSpot legge lo stato nascosto', () async {
      respondWith([spotRow('1', status: 'hidden')]);

      final spot = await dataSource.getSpot('1');

      expect(spot.status, SpotStatus.hidden);
    });

    test('senza status lo spot è pubblicato', () async {
      respondWith([spotRow('1')]);

      final spot = await dataSource.getSpot('1');

      expect(spot.status, SpotStatus.published);
    });

    test('getMySpots legge lo stato dei propri spot', () async {
      respondWith([
        {
          ...spotRow('1', likeCount: 0, commentCount: 0, likedByMe: false),
          'channel_name': 'Spotted Pisa',
          'channel_slug': 'spotted-pisa',
          'status': 'hidden',
        },
      ]);

      final spots = await dataSource.getMySpots(offset: 0, limit: 20);

      expect(spots.single.spot.status, SpotStatus.hidden);
    });
  });

  group('getChannelSpots: ricerca', () {
    Map<String, dynamic> sentBody() =>
        jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;

    test(
      'senza testo la richiesta è quella di sempre (niente p_query)',
      () async {
        respondWith(<Object>[]);

        await dataSource.getChannelSpots(channelId: 'c1', offset: 0, limit: 20);

        expect(sentBody(), {
          'p_channel_id': 'c1',
          'p_limit': 20,
          'p_offset': 0,
        });
        expect(sentBody().containsKey('p_query'), isFalse);
      },
    );

    test('con un testo lo invia come p_query', () async {
      respondWith(<Object>[]);

      await dataSource.getChannelSpots(
        channelId: 'c1',
        offset: 20,
        limit: 20,
        query: 'ombrello',
      );

      expect(sentBody(), {
        'p_channel_id': 'c1',
        'p_limit': 20,
        'p_offset': 20,
        'p_query': 'ombrello',
      });
    });

    test('toglie gli spazi ai bordi del testo', () async {
      respondWith(<Object>[]);

      await dataSource.getChannelSpots(
        channelId: 'c1',
        offset: 0,
        limit: 20,
        query: '  perché  ',
      );

      expect(sentBody()['p_query'], 'perché');
    });

    test('un testo vuoto o di soli spazi non è una ricerca', () async {
      respondWith(<Object>[]);

      await dataSource.getChannelSpots(
        channelId: 'c1',
        offset: 0,
        limit: 20,
        query: '   ',
      );

      expect(sentBody().containsKey('p_query'), isFalse);
    });

    test('i simboli speciali partono così come sono', () async {
      respondWith(<Object>[]);

      await dataSource.getChannelSpots(
        channelId: 'c1',
        offset: 0,
        limit: 20,
        query: r'100% a_b \',
      );

      expect(sentBody()['p_query'], r'100% a_b \');
    });

    test('legge i risultati come l elenco normale', () async {
      respondWith([
        spotRow('1', title: 'Ombrello perso', likeCount: 2, commentCount: 1),
      ]);

      final spots = await dataSource.getChannelSpots(
        channelId: 'c1',
        offset: 0,
        limit: 20,
        query: 'ombrello',
      );

      expect(spots.single.title, 'Ombrello perso');
      expect(spots.single.stats.likeCount, 2);
    });
  });
}
