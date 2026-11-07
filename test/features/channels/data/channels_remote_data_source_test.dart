import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/data/datasources/channels_remote_data_source.dart';
import 'package:spotted/features/channels/data/models/channel_dto.dart';
import 'package:spotted/features/channels/data/repositories/channels_repository_impl.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabase supabase;
  late ChannelsRemoteDataSource dataSource;

  void respondWith(Object body, {int status = 200}) {
    supabase = MockSupabase((_) async => jsonResponse(body, status: status));
    dataSource = ChannelsRemoteDataSource(
      supabase.client,
      currentUserId: () => 'user-1',
    );
  }

  group('getChannels', () {
    test('legge le righe e le converte in entità', () async {
      respondWith([
        channelRow('1', name: 'Spotted Pisa', topicId: 't1', place: 'Pisa'),
      ]);

      final channels = await dataSource.getChannels(offset: 0, limit: 20);

      expect(channels.single.name, 'Spotted Pisa');
      expect(channels.single.topicId, 't1');
      expect(channels.single.place, 'Pisa');
      expect(channels.single.createdAt, DateTime.utc(2026, 1, 1, 10));
    });

    test('chiede solo le colonne pubbliche, mai owner_id', () async {
      respondWith(<Object>[]);

      await dataSource.getChannels(offset: 0, limit: 20);

      final query = supabase.lastRequest.url.queryParameters;
      expect(query['select'], channelColumns.replaceAll(' ', ''));
      expect(query['select'], isNot(contains('owner_id')));
      expect(supabase.lastRequest.url.path, '/rest/v1/channels');
    });

    test('ordina per data decrescente e poi per id', () async {
      respondWith(<Object>[]);

      await dataSource.getChannels(offset: 0, limit: 20);

      final order = supabase.lastRequest.url.queryParametersAll['order']!.join(
        ',',
      );
      expect(order, contains('created_at.desc'));
      expect(order, contains('id'));
    });

    test('paginazione: offset e limite', () async {
      respondWith(<Object>[]);

      await dataSource.getChannels(offset: 40, limit: 20);

      final query = supabase.lastRequest.url.queryParameters;
      expect(query['offset'], '40');
      expect(query['limit'], '20');
    });

    test('filtra per topic e per nome', () async {
      respondWith(<Object>[]);

      await dataSource.getChannels(
        offset: 0,
        limit: 20,
        query: 'pisa',
        topicId: 't1',
      );

      final query = supabase.lastRequest.url.queryParameters;
      expect(query['topic_id'], 'eq.t1');
      expect(query['name'], 'ilike.%pisa%');
    });

    test('rende letterali % e _ nella ricerca', () async {
      respondWith(<Object>[]);

      await dataSource.getChannels(offset: 0, limit: 20, query: '100%_ok');

      expect(
        supabase.lastRequest.url.queryParameters['name'],
        r'ilike.%100\%\_ok%',
      );
    });

    test('senza filtri non manda topic_id né name', () async {
      respondWith(<Object>[]);

      await dataSource.getChannels(offset: 0, limit: 20);

      final query = supabase.lastRequest.url.queryParameters;
      expect(query.containsKey('topic_id'), isFalse);
      expect(query.containsKey('name'), isFalse);
    });
  });

  group('getChannelBySlug', () {
    test('trovato', () async {
      respondWith([channelRow('1')]);

      final channel = await dataSource.getChannelBySlug('canale-1');

      expect(channel.slug, 'canale-1');
      expect(supabase.lastRequest.url.queryParameters['slug'], 'eq.canale-1');
    });

    test('non trovato: NotFoundFailure', () async {
      respondWith(<Object>[]);

      await expectLater(
        dataSource.getChannelBySlug('manca'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  test('getMyChannels chiama l RPC my_channels', () async {
    respondWith([channelRow('1'), channelRow('2')]);

    final channels = await dataSource.getMyChannels();

    expect(channels, hasLength(2));
    expect(supabase.lastRequest.method, 'POST');
    expect(supabase.lastRequest.url.path, '/rest/v1/rpc/my_channels');
  });

  group('createChannel', () {
    test('invia owner_id, campi e chiede solo colonne pubbliche', () async {
      // `.single()` si aspetta un oggetto, non una lista.
      respondWith(channelRow('1', name: 'Spotted Pisa'));

      final channel = await dataSource.createChannel(
        name: 'Spotted Pisa',
        slug: 'spotted-pisa',
        description: 'Descrizione',
        place: 'Pisa',
        topicId: 't1',
      );

      expect(channel.name, 'Spotted Pisa');
      expect(supabase.lastRequest.method, 'POST');
      expect(
        supabase.lastRequest.url.queryParameters['select'],
        channelColumns.replaceAll(' ', ''),
      );
      expect(jsonDecode(supabase.lastRequest.body), {
        'owner_id': 'user-1',
        'name': 'Spotted Pisa',
        'slug': 'spotted-pisa',
        'description': 'Descrizione',
        'place': 'Pisa',
        'topic_id': 't1',
      });
    });

    test('senza utente loggato: AuthFailure e nessuna richiesta', () async {
      supabase = MockSupabase((_) async => jsonResponse(<Object>[]));
      dataSource = ChannelsRemoteDataSource(
        supabase.client,
        currentUserId: () => null,
      );

      await expectLater(
        dataSource.createChannel(name: 'Spotted Pisa', slug: 'spotted-pisa'),
        throwsA(isA<AuthFailure>()),
      );
      expect(supabase.requests, isEmpty);
    });
  });

  group('errori attraverso il repository', () {
    ChannelsRepositoryImpl repositoryFor(MockSupabase supabase) {
      return ChannelsRepositoryImpl(
        ChannelsRemoteDataSource(
          supabase.client,
          currentUserId: () => 'user-1',
        ),
      );
    }

    test('slug duplicato (23505): ConflictFailure', () async {
      final repository = repositoryFor(
        MockSupabase(
          (_) async => postgrestError(
            '23505',
            'duplicate key value violates unique constraint',
            status: 409,
          ),
        ),
      );

      await expectLater(
        repository.createChannel(name: 'Spotted', slug: 'spotted'),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('permesso negato (42501): UnknownFailure', () async {
      final repository = repositoryFor(
        MockSupabase(
          (_) async =>
              postgrestError('42501', 'permission denied', status: 403),
        ),
      );

      await expectLater(
        repository.getChannels(offset: 0, limit: 20),
        throwsA(isA<UnknownFailure>()),
      );
    });

    test('riga con tipi inattesi: UnknownFailure, non un crash', () async {
      final repository = repositoryFor(
        MockSupabase(
          (_) async => jsonResponse([
            {'id': 1, 'name': 'senza slug', 'created_at': 'non-una-data'},
          ]),
        ),
      );

      await expectLater(
        repository.getChannels(offset: 0, limit: 20),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });
}
