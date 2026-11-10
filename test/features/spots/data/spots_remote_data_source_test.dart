import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/data/datasources/spots_remote_data_source.dart';
import 'package:spotted/features/spots/data/models/spot_dto.dart';
import 'package:spotted/features/spots/data/repositories/spots_repository_impl.dart';

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
    test('legge le righe e le converte in entità', () async {
      respondWith([spotRow('1', title: 'Ciao', content: 'Mondo')]);

      final spots = await dataSource.getChannelSpots(
        channelId: 'c1',
        offset: 0,
        limit: 20,
      );

      expect(spots.single.title, 'Ciao');
      expect(spots.single.content, 'Mondo');
      expect(spots.single.channelId, 'c1');
      expect(spots.single.createdAt, DateTime.utc(2026, 1, 1, 10));
    });

    test('chiede solo le colonne pubbliche, mai author_id', () async {
      respondWith(<Object>[]);

      await dataSource.getChannelSpots(channelId: 'c1', offset: 0, limit: 20);

      final query = supabase.lastRequest.url.queryParameters;
      expect(query['select'], spotColumns.replaceAll(' ', ''));
      expect(query['select'], isNot(contains('author_id')));
      expect(supabase.lastRequest.url.path, '/rest/v1/spots');
    });

    test('filtra per canale, dal più recente, con offset e limite', () async {
      respondWith(<Object>[]);

      await dataSource.getChannelSpots(channelId: 'c1', offset: 40, limit: 20);

      final query = supabase.lastRequest.url.queryParameters;
      expect(query['channel_id'], 'eq.c1');
      expect(query['offset'], '40');
      expect(query['limit'], '20');
      final order = supabase.lastRequest.url.queryParametersAll['order']!.join(
        ',',
      );
      expect(order, contains('created_at.desc'));
      expect(order, contains('id'));
    });
  });

  group('getMySpots', () {
    test("chiama l'RPC my_spots_page e legge il canale", () async {
      respondWith([
        {
          ...spotRow('1'),
          'channel_name': 'Spotted Pisa',
          'channel_slug': 'spotted-pisa',
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
    });
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
}
