import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/news/data/models/news_dto.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le news dei canali. La tabella è chiusa ai client: si usano solo gli RPC
/// (`channel_news_page`, `followed_news_page`, `news_detail`,
/// `create_channel_news`, `update_channel_news`, `delete_channel_news`).
class NewsRemoteDataSource {
  NewsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<ChannelNews>> getChannelNews({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'channel_news_page',
      params: {
        'p_channel_id': channelId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return _toNews(rows);
  }

  /// Usa l'RPC `followed_news_page`: le news dei canali seguiti.
  Future<List<ChannelNews>> getFollowedNews({
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'followed_news_page',
      params: {'p_limit': limit, 'p_offset': offset},
    );
    return _toNews(rows);
  }

  Future<ChannelNews> getNews(String newsId) async {
    final rows = await _client.rpc<List<dynamic>>(
      'news_detail',
      params: {'p_news_id': newsId},
    );
    return _single(rows);
  }

  Future<ChannelNews> createNews({
    required String channelId,
    required String title,
    required String body,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'create_channel_news',
      params: {'p_channel_id': channelId, 'p_title': title, 'p_body': body},
    );
    return _single(rows);
  }

  Future<ChannelNews> updateNews({
    required String newsId,
    required String title,
    required String body,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'update_channel_news',
      params: {'p_news_id': newsId, 'p_title': title, 'p_body': body},
    );
    return _single(rows);
  }

  /// L'RPC risponde `false` se la news non esiste.
  Future<void> deleteNews(String newsId) async {
    final deleted = await _client.rpc<bool>(
      'delete_channel_news',
      params: {'p_news_id': newsId},
    );
    if (!deleted) throw const NotFoundFailure();
  }

  ChannelNews _single(List<dynamic> rows) {
    final news = _toNews(rows);
    if (news.isEmpty) throw const NotFoundFailure();
    return news.single;
  }

  List<ChannelNews> _toNews(List<dynamic> rows) => rows
      .cast<Map<String, dynamic>>()
      .map((row) => NewsDto.fromJson(row).toEntity())
      .toList();
}
