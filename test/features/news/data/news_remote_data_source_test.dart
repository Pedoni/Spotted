import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/news/data/datasources/news_remote_data_source.dart';
import 'package:spotted/features/news/data/repositories/news_repository_impl.dart';

import '../../../helpers/mock_supabase.dart';

Map<String, dynamic> newsRow(String id, {String title = 'Orari estivi'}) => {
  'id': id,
  'channel_id': 'c1',
  'channel_name': 'Spotted Pisa',
  'channel_slug': 'spotted-pisa',
  'title': title,
  'body': 'Da lunedì apriamo alle 9.',
  'created_at': '2026-03-01T10:00:00+00:00',
};

void main() {
  late MockSupabase supabase;
  late NewsRemoteDataSource dataSource;
  late NewsRepositoryImpl repository;

  void respondWith(Object body, {int status = 200}) {
    supabase = MockSupabase((_) async => jsonResponse(body, status: status));
    dataSource = NewsRemoteDataSource(supabase.client);
    repository = NewsRepositoryImpl(dataSource);
  }

  void respondError(String code, String message) {
    supabase = MockSupabase((_) async => postgrestError(code, message));
    dataSource = NewsRemoteDataSource(supabase.client);
    repository = NewsRepositoryImpl(dataSource);
  }

  Map<String, dynamic> sentBody() =>
      jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;

  group('getChannelNews', () {
    test("chiama l'RPC channel_news_page con canale e paginazione", () async {
      respondWith(<Object>[]);

      await dataSource.getChannelNews(channelId: 'c1', offset: 40, limit: 20);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/channel_news_page');
      expect(sentBody(), {'p_channel_id': 'c1', 'p_limit': 20, 'p_offset': 40});
    });

    test('legge le news con il canale, senza autore', () async {
      respondWith([newsRow('n1'), newsRow('n2', title: 'Chiusura')]);

      final news = await dataSource.getChannelNews(
        channelId: 'c1',
        offset: 0,
        limit: 20,
      );

      expect(news.map((n) => n.title), ['Orari estivi', 'Chiusura']);
      expect(news.first.channelName, 'Spotted Pisa');
      expect(news.first.channelSlug, 'spotted-pisa');
      expect(news.first.createdAt, DateTime.utc(2026, 3, 1, 10));
    });
  });

  group('getFollowedNews', () {
    test("chiama l'RPC followed_news_page, senza canale", () async {
      respondWith(<Object>[]);

      await dataSource.getFollowedNews(offset: 20, limit: 20);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/followed_news_page');
      expect(sentBody(), {'p_limit': 20, 'p_offset': 20});
    });

    test('legge le news con il canale di ognuna', () async {
      respondWith([newsRow('n1'), newsRow('n2', title: 'Chiusura')]);

      final news = await dataSource.getFollowedNews(offset: 0, limit: 20);

      expect(news.map((n) => n.title), ['Orari estivi', 'Chiusura']);
      expect(news.first.channelSlug, 'spotted-pisa');
    });

    test('errore di rete: NetworkFailure', () async {
      supabase = MockSupabase((_) async => throw const SocketException('x'));
      repository = NewsRepositoryImpl(NewsRemoteDataSource(supabase.client));

      expect(
        repository.getFollowedNews(offset: 0, limit: 20),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('getNews', () {
    test("chiama l'RPC news_detail", () async {
      respondWith([newsRow('n1')]);

      final news = await dataSource.getNews('n1');

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/news_detail');
      expect(sentBody(), {'p_news_id': 'n1'});
      expect(news.id, 'n1');
    });

    test('non esiste: NotFoundFailure', () async {
      respondWith(<Object>[]);

      expect(repository.getNews('n1'), throwsA(isA<NotFoundFailure>()));
    });
  });

  group('createNews', () {
    test("chiama l'RPC create_channel_news e restituisce la news", () async {
      respondWith([newsRow('n1')]);

      final news = await dataSource.createNews(
        channelId: 'c1',
        title: 'Orari estivi',
        body: 'Da lunedì apriamo alle 9.',
      );

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/create_channel_news',
      );
      expect(sentBody(), {
        'p_channel_id': 'c1',
        'p_title': 'Orari estivi',
        'p_body': 'Da lunedì apriamo alle 9.',
      });
      expect(news.id, 'n1');
    });

    test('chi non è il proprietario: PermissionFailure', () async {
      respondError('42501', 'not the channel owner');

      expect(
        repository.createNews(channelId: 'c1', title: 't', body: 'b'),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('titolo o testo non validi: ValidationFailure', () async {
      respondError('23514', 'invalid news title');

      expect(
        repository.createNews(channelId: 'c1', title: 't', body: 'b'),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('updateNews', () {
    test("chiama l'RPC update_channel_news", () async {
      respondWith([newsRow('n1', title: 'Nuovo titolo')]);

      final news = await dataSource.updateNews(
        newsId: 'n1',
        title: 'Nuovo titolo',
        body: 'Nuovo testo',
      );

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/update_channel_news',
      );
      expect(sentBody(), {
        'p_news_id': 'n1',
        'p_title': 'Nuovo titolo',
        'p_body': 'Nuovo testo',
      });
      expect(news.title, 'Nuovo titolo');
    });

    test('la news non esiste: NotFoundFailure', () async {
      respondWith(<Object>[]);

      expect(
        repository.updateNews(newsId: 'n1', title: 't', body: 'b'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('chi non è il proprietario: PermissionFailure', () async {
      respondError('42501', 'not the channel owner');

      expect(
        repository.updateNews(newsId: 'n1', title: 't', body: 'b'),
        throwsA(isA<PermissionFailure>()),
      );
    });
  });

  group('deleteNews', () {
    test("chiama l'RPC delete_channel_news", () async {
      respondWith(true);

      await dataSource.deleteNews('n1');

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/delete_channel_news',
      );
      expect(sentBody(), {'p_news_id': 'n1'});
    });

    test('la news non esiste (risposta false): NotFoundFailure', () async {
      respondWith(false);

      expect(repository.deleteNews('n1'), throwsA(isA<NotFoundFailure>()));
    });

    test('chi non è il proprietario: PermissionFailure', () async {
      respondError('42501', 'not the channel owner');

      expect(repository.deleteNews('n1'), throwsA(isA<PermissionFailure>()));
    });
  });

  test('una risposta con tipi inattesi diventa UnknownFailure', () async {
    respondWith([
      {...newsRow('n1'), 'title': null},
    ]);

    expect(
      repository.getChannelNews(channelId: 'c1', offset: 0, limit: 20),
      throwsA(isA<UnknownFailure>()),
    );
  });
}
