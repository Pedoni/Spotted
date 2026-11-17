import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/events/data/datasources/events_remote_data_source.dart';
import 'package:spotted/features/events/data/repositories/events_repository_impl.dart';
import 'package:spotted/features/events/domain/entities/events_when.dart';

import '../../../helpers/mock_supabase.dart';

Map<String, dynamic> eventRow(
  String id, {
  String title = 'Aperitivo di benvenuto',
  String? location = 'Aula magna',
  String? endsAt = '2026-03-14T20:00:00+00:00',
}) => {
  'id': id,
  'channel_id': 'c1',
  'channel_name': 'Spotted Pisa',
  'channel_slug': 'spotted-pisa',
  'title': title,
  'description': 'Un aperitivo per conoscersi.',
  'location': location,
  'starts_at': '2026-03-14T18:00:00+00:00',
  'ends_at': endsAt,
  'created_at': '2026-03-01T10:00:00+00:00',
};

void main() {
  late MockSupabase supabase;
  late EventsRemoteDataSource dataSource;
  late EventsRepositoryImpl repository;

  void respondWith(Object body) {
    supabase = MockSupabase((_) async => jsonResponse(body));
    dataSource = EventsRemoteDataSource(supabase.client);
    repository = EventsRepositoryImpl(dataSource);
  }

  void respondError(String code, String message) {
    supabase = MockSupabase((_) async => postgrestError(code, message));
    dataSource = EventsRemoteDataSource(supabase.client);
    repository = EventsRepositoryImpl(dataSource);
  }

  Map<String, dynamic> sentBody() =>
      jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;

  group('getChannelEvents', () {
    test(
      "chiama l'RPC channel_events_page con canale, periodo e pagina",
      () async {
        respondWith(<Object>[]);

        await dataSource.getChannelEvents(
          channelId: 'c1',
          when: EventsWhen.past,
          offset: 40,
          limit: 20,
        );

        expect(
          supabase.lastRequest.url.path,
          '/rest/v1/rpc/channel_events_page',
        );
        expect(sentBody(), {
          'p_channel_id': 'c1',
          'p_when': 'past',
          'p_limit': 20,
          'p_offset': 40,
        });
      },
    );

    test('manda upcoming per i prossimi', () async {
      respondWith(<Object>[]);

      await dataSource.getChannelEvents(
        channelId: 'c1',
        when: EventsWhen.upcoming,
        offset: 0,
        limit: 20,
      );

      expect(sentBody()['p_when'], 'upcoming');
    });

    test('legge gli eventi con canale, luogo e date', () async {
      respondWith([
        eventRow('e1'),
        eventRow('e2', location: null, endsAt: null),
      ]);

      final events = await dataSource.getChannelEvents(
        channelId: 'c1',
        when: EventsWhen.upcoming,
        offset: 0,
        limit: 20,
      );

      expect(events, hasLength(2));
      expect(events.first.channelName, 'Spotted Pisa');
      expect(events.first.location, 'Aula magna');
      expect(events.first.startsAt, DateTime.utc(2026, 3, 14, 18));
      expect(events.first.endsAt, DateTime.utc(2026, 3, 14, 20));
      expect(events.last.location, isNull);
      expect(events.last.endsAt, isNull);
    });
  });

  group('getFollowedEvents', () {
    test("chiama l'RPC followed_events_page, senza canale", () async {
      respondWith(<Object>[]);

      await dataSource.getFollowedEvents(offset: 20, limit: 20);

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/followed_events_page',
      );
      expect(sentBody(), {'p_limit': 20, 'p_offset': 20});
    });

    test('legge gli eventi con il canale di ognuno', () async {
      respondWith([eventRow('e1'), eventRow('e2', location: null)]);

      final events = await dataSource.getFollowedEvents(offset: 0, limit: 20);

      expect(events.map((e) => e.id), ['e1', 'e2']);
      expect(events.first.channelSlug, 'spotted-pisa');
      expect(events.last.location, isNull);
    });

    test('errore di rete: NetworkFailure', () async {
      supabase = MockSupabase((_) async => throw const SocketException('x'));
      repository = EventsRepositoryImpl(
        EventsRemoteDataSource(supabase.client),
      );

      expect(
        repository.getFollowedEvents(offset: 0, limit: 20),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('getEvent', () {
    test("chiama l'RPC event_detail", () async {
      respondWith([eventRow('e1')]);

      final event = await dataSource.getEvent('e1');

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/event_detail');
      expect(sentBody(), {'p_event_id': 'e1'});
      expect(event.id, 'e1');
    });

    test('non esiste: NotFoundFailure', () async {
      respondWith(<Object>[]);

      expect(repository.getEvent('e1'), throwsA(isA<NotFoundFailure>()));
    });
  });

  group('createEvent', () {
    test('manda i campi e le date in UTC', () async {
      respondWith([eventRow('e1')]);

      final event = await dataSource.createEvent(
        channelId: 'c1',
        title: 'Aperitivo',
        description: 'Descrizione',
        location: 'Aula magna',
        startsAt: DateTime.utc(2026, 3, 14, 18),
        endsAt: DateTime.utc(2026, 3, 14, 20),
      );

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/create_channel_event',
      );
      expect(sentBody(), {
        'p_channel_id': 'c1',
        'p_title': 'Aperitivo',
        'p_description': 'Descrizione',
        'p_location': 'Aula magna',
        'p_starts_at': '2026-03-14T18:00:00.000Z',
        'p_ends_at': '2026-03-14T20:00:00.000Z',
      });
      expect(event.id, 'e1');
    });

    test('un orario locale viene mandato come UTC', () async {
      respondWith([eventRow('e1')]);
      final local = DateTime(2026, 3, 14, 18);

      await dataSource.createEvent(
        channelId: 'c1',
        title: 't',
        description: 'd',
        startsAt: local,
      );

      expect(sentBody()['p_starts_at'], local.toUtc().toIso8601String());
    });

    test('senza luogo e fine manda null', () async {
      respondWith([eventRow('e1')]);

      await dataSource.createEvent(
        channelId: 'c1',
        title: 't',
        description: 'd',
        startsAt: DateTime.utc(2026, 3, 14, 18),
      );

      expect(sentBody()['p_location'], isNull);
      expect(sentBody()['p_ends_at'], isNull);
      expect(sentBody().containsKey('p_location'), isTrue);
    });

    test('chi non è il proprietario: PermissionFailure', () async {
      respondError('42501', 'not the channel owner');

      expect(
        repository.createEvent(
          channelId: 'c1',
          title: 't',
          description: 'd',
          startsAt: DateTime.utc(2026),
        ),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('date o campi non validi: ValidationFailure', () async {
      respondError('23514', 'invalid event dates');

      expect(
        repository.createEvent(
          channelId: 'c1',
          title: 't',
          description: 'd',
          startsAt: DateTime.utc(2026),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('updateEvent', () {
    test("chiama l'RPC update_channel_event", () async {
      respondWith([eventRow('e1', title: 'Nuovo')]);

      final event = await dataSource.updateEvent(
        eventId: 'e1',
        title: 'Nuovo',
        description: 'Testo',
        startsAt: DateTime.utc(2026, 3, 14, 18),
      );

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/update_channel_event',
      );
      expect(sentBody()['p_event_id'], 'e1');
      expect(sentBody()['p_title'], 'Nuovo');
      expect(event.title, 'Nuovo');
    });

    test("l'evento non esiste: NotFoundFailure", () async {
      respondWith(<Object>[]);

      expect(
        repository.updateEvent(
          eventId: 'e1',
          title: 't',
          description: 'd',
          startsAt: DateTime.utc(2026),
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('chi non è il proprietario: PermissionFailure', () async {
      respondError('42501', 'not the channel owner');

      expect(
        repository.updateEvent(
          eventId: 'e1',
          title: 't',
          description: 'd',
          startsAt: DateTime.utc(2026),
        ),
        throwsA(isA<PermissionFailure>()),
      );
    });
  });

  group('deleteEvent', () {
    test("chiama l'RPC delete_channel_event", () async {
      respondWith(true);

      await dataSource.deleteEvent('e1');

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/delete_channel_event',
      );
      expect(sentBody(), {'p_event_id': 'e1'});
    });

    test("l'evento non esiste (risposta false): NotFoundFailure", () async {
      respondWith(false);

      expect(repository.deleteEvent('e1'), throwsA(isA<NotFoundFailure>()));
    });

    test('chi non è il proprietario: PermissionFailure', () async {
      respondError('42501', 'not the channel owner');

      expect(repository.deleteEvent('e1'), throwsA(isA<PermissionFailure>()));
    });
  });

  test('una risposta con tipi inattesi diventa UnknownFailure', () async {
    respondWith([
      {...eventRow('e1'), 'starts_at': null},
    ]);

    expect(
      repository.getChannelEvents(
        channelId: 'c1',
        when: EventsWhen.upcoming,
        offset: 0,
        limit: 20,
      ),
      throwsA(isA<UnknownFailure>()),
    );
  });
}
