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

  group('getChannelsMap', () {
    Map<String, dynamic> pinRow(
      String code, {
      int count = 1,
      bool single = true,
    }) => {
      'municipality_id': code,
      'municipality_label': 'Pisa (PI)',
      'latitude': 43.7228,
      'longitude': 10.4017,
      'channel_count': count,
      'channel_id': single ? 'c1' : null,
      'channel_name': single ? 'Spotted Pisa' : null,
      'channel_slug': single ? 'spotted-pisa' : null,
      'channel_avatar_path': single ? 'c1/avatar-1.jpg' : null,
    };

    Map<String, dynamic> sentBody() =>
        jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;

    test(
      "chiama l'RPC channels_map, senza filtri non manda parametri",
      () async {
        respondWith(<Object>[]);

        await dataSource.getChannelsMap();

        expect(supabase.lastRequest.url.path, '/rest/v1/rpc/channels_map');
        expect(sentBody(), isEmpty);
      },
    );

    test('manda solo i filtri attivi, con i nomi dei parametri', () async {
      respondWith(<Object>[]);

      await dataSource.getChannelsMap(
        query: 'pisa',
        topicId: 't1',
        regionName: 'Toscana',
        provinceCode: 'PI',
        municipalityId: '050026',
      );

      expect(sentBody(), {
        'p_query': 'pisa',
        'p_topic_id': 't1',
        'p_region_name': 'Toscana',
        'p_province_code': 'PI',
        'p_municipality_id': '050026',
      });
    });

    test('un comune con un solo canale ha il canale', () async {
      respondWith([pinRow('050026')]);

      final pin = (await dataSource.getChannelsMap()).single;

      expect(pin.municipalityId, '050026');
      expect(pin.municipalityLabel, 'Pisa (PI)');
      expect(pin.latitude, 43.7228);
      expect(pin.longitude, 10.4017);
      expect(pin.channelCount, 1);
      expect(pin.channel?.id, 'c1');
      expect(pin.channel?.name, 'Spotted Pisa');
      expect(pin.channel?.slug, 'spotted-pisa');
      expect(pin.channel?.avatarPath, 'c1/avatar-1.jpg');
    });

    test('un comune con più canali non ha il canale, ma il numero', () async {
      respondWith([pinRow('050026', count: 7, single: false)]);

      final pin = (await dataSource.getChannelsMap()).single;

      expect(pin.channelCount, 7);
      expect(pin.channel, isNull);
    });

    test('le coordinate intere si leggono come numeri decimali', () async {
      respondWith([
        {...pinRow('050026'), 'latitude': 44, 'longitude': 10},
      ]);

      final pin = (await dataSource.getChannelsMap()).single;

      expect(pin.latitude, 44.0);
      expect(pin.longitude, 10.0);
    });

    test(
      'errori: la rete diventa NetworkFailure, il resto UnknownFailure',
      () async {
        supabase = MockSupabase((_) async => postgrestError('XX000', 'boom'));
        final repository = ChannelsRepositoryImpl(
          ChannelsRemoteDataSource(supabase.client, currentUserId: () => 'u'),
        );

        await expectLater(
          repository.getChannelsMap(),
          throwsA(isA<UnknownFailure>()),
        );
      },
    );
  });

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

    test('legge il comune, la provincia e la regione, se ci sono', () async {
      respondWith([
        channelRow(
          '1',
          place: 'Pisa (PI)',
          municipalityId: '050026',
          provinceCode: 'PI',
          regionName: 'Toscana',
        ),
        channelRow('2', name: 'Università online'),
      ]);

      final channels = await dataSource.getChannels(offset: 0, limit: 20);

      expect(channels[0].municipalityId, '050026');
      expect(channels[0].provinceCode, 'PI');
      expect(channels[0].regionName, 'Toscana');
      expect(channels[0].place, 'Pisa (PI)');
      // Il comune è facoltativo: un canale può non averlo.
      expect(channels[1].municipalityId, isNull);
      expect(channels[1].provinceCode, isNull);
      expect(channels[1].regionName, isNull);
      expect(channels[1].place, isNull);
    });

    test('chiede anche le colonne del comune', () async {
      respondWith(<Object>[]);

      await dataSource.getChannels(offset: 0, limit: 20);

      final select = supabase.lastRequest.url.queryParameters['select']!;
      expect(select, contains('municipality_id'));
      expect(select, contains('province_code'));
      expect(select, contains('region_name'));
    });

    test('chiede anche i percorsi di foto e copertina', () async {
      respondWith(<Object>[]);

      await dataSource.getChannels(offset: 0, limit: 20);

      final select = supabase.lastRequest.url.queryParameters['select']!;
      expect(select, contains('avatar_path'));
      expect(select, contains('cover_path'));
    });

    test('legge i percorsi di foto e copertina, o null se mancano', () async {
      respondWith([
        channelRow(
          '1',
          avatarPath: 'c1/avatar-1.jpg',
          coverPath: 'c1/cover-2.jpg',
        ),
        channelRow('2'),
      ]);

      final channels = await dataSource.getChannels(offset: 0, limit: 20);

      expect(channels[0].avatarPath, 'c1/avatar-1.jpg');
      expect(channels[0].coverPath, 'c1/cover-2.jpg');
      expect(channels[1].avatarPath, isNull);
      expect(channels[1].coverPath, isNull);
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

    test('filtra per regione, provincia e comune', () async {
      respondWith(<Object>[]);

      await dataSource.getChannels(
        offset: 0,
        limit: 20,
        regionName: 'Emilia-Romagna',
        provinceCode: 'FC',
        municipalityId: '008888',
      );

      final query = supabase.lastRequest.url.queryParameters;
      expect(query['region_name'], 'eq.Emilia-Romagna');
      expect(query['province_code'], 'eq.FC');
      expect(query['municipality_id'], 'eq.008888');
    });

    test('rende letterali % e _ nella ricerca', () async {
      respondWith(<Object>[]);

      await dataSource.getChannels(offset: 0, limit: 20, query: '100%_ok');

      expect(
        supabase.lastRequest.url.queryParameters['name'],
        r'ilike.%100\%\_ok%',
      );
    });

    test('senza filtri non manda nessun filtro', () async {
      respondWith(<Object>[]);

      await dataSource.getChannels(offset: 0, limit: 20);

      final query = supabase.lastRequest.url.queryParameters;
      expect(query.containsKey('topic_id'), isFalse);
      expect(query.containsKey('name'), isFalse);
      expect(query.containsKey('region_name'), isFalse);
      expect(query.containsKey('province_code'), isFalse);
      expect(query.containsKey('municipality_id'), isFalse);
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
        municipalityId: '050026',
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
        'municipality_id': '050026',
        'topic_id': 't1',
      });
    });

    test(
      'non scrive mai il luogo: lo calcola il database dal comune',
      () async {
        respondWith(channelRow('1'));

        await dataSource.createChannel(
          name: 'Spotted Pisa',
          slug: 'spotted-pisa',
          municipalityId: '050026',
        );

        final body =
            jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;
        expect(body.containsKey('place'), isFalse);
        expect(body.containsKey('province_code'), isFalse);
        expect(body.containsKey('region_name'), isFalse);
      },
    );

    test('senza comune: il comune resta vuoto (è facoltativo)', () async {
      respondWith(channelRow('1'));

      await dataSource.createChannel(
        name: 'Università online',
        slug: 'uni-online',
      );

      final body =
          jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;
      expect(body['municipality_id'], isNull);
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

  group('updateChannel', () {
    final row = channelRow('1', name: 'Nuovo nome', municipalityId: '050026');

    test(
      "chiama l'RPC update_channel con i parametri e legge il canale",
      () async {
        respondWith([row]);

        final channel = await dataSource.updateChannel(
          channelId: 'c1',
          name: 'Nuovo nome',
          description: 'Descrizione',
          topicId: 't1',
          municipalityId: '050026',
        );

        expect(supabase.lastRequest.url.path, '/rest/v1/rpc/update_channel');
        expect(jsonDecode(supabase.lastRequest.body), {
          'p_channel_id': 'c1',
          'p_name': 'Nuovo nome',
          'p_description': 'Descrizione',
          'p_topic_id': 't1',
          'p_municipality_id': '050026',
        });
        expect(channel.name, 'Nuovo nome');
        expect(channel.municipalityId, '050026');
      },
    );

    test('non manda lo slug: non si cambia', () async {
      respondWith([row]);

      await dataSource.updateChannel(channelId: 'c1', name: 'Nuovo nome');

      final body = jsonDecode(supabase.lastRequest.body) as Map;
      expect(body.keys, isNot(contains('p_slug')));
      expect(body['p_description'], isNull);
      expect(body['p_topic_id'], isNull);
      expect(body['p_municipality_id'], isNull);
    });

    test('nessuna riga: NotFoundFailure', () async {
      respondWith(<Object>[]);

      await expectLater(
        dataSource.updateChannel(channelId: 'c1', name: 'Nome'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('deleteChannel', () {
    test("chiama l'RPC delete_channel con l'id", () async {
      // Una funzione che non restituisce niente risponde `null`.
      supabase = MockSupabase((_) async => jsonResponse(null));
      dataSource = ChannelsRemoteDataSource(
        supabase.client,
        currentUserId: () => 'user-1',
      );

      await dataSource.deleteChannel('c1');

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/delete_channel');
      expect(jsonDecode(supabase.lastRequest.body), {'p_channel_id': 'c1'});
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

    test('permesso negato (42501): PermissionFailure', () async {
      final repository = repositoryFor(
        MockSupabase(
          (_) async =>
              postgrestError('42501', 'permission denied', status: 403),
        ),
      );

      await expectLater(
        repository.getChannels(offset: 0, limit: 20),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('modifica: non proprietario (42501): PermissionFailure', () async {
      final repository = repositoryFor(
        MockSupabase(
          (_) async =>
              postgrestError('42501', 'not the channel owner', status: 403),
        ),
      );

      await expectLater(
        repository.updateChannel(channelId: 'c1', name: 'Nome'),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('modifica: nome non valido (23514): ValidationFailure', () async {
      final repository = repositoryFor(
        MockSupabase(
          (_) async => postgrestError('23514', 'invalid channel name'),
        ),
      );

      await expectLater(
        repository.updateChannel(channelId: 'c1', name: 'No'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('eliminazione: non proprietario (42501): PermissionFailure', () async {
      final repository = repositoryFor(
        MockSupabase(
          (_) async =>
              postgrestError('42501', 'not the channel owner', status: 403),
        ),
      );

      await expectLater(
        repository.deleteChannel('c1'),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('errore del server sconosciuto: UnknownFailure', () async {
      final repository = repositoryFor(
        MockSupabase(
          (_) async => postgrestError('XX000', 'boom', status: 500),
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
