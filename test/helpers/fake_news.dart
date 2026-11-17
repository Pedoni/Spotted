import 'dart:async';

import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/domain/repositories/news_repository.dart';

ChannelNews makeNews(
  int i, {
  String channelId = 'c1',
  String channelName = 'Canale 1',
  String channelSlug = 'canale-1',
  String? title,
  String? body,
}) {
  return ChannelNews(
    id: 'n$i',
    channelId: channelId,
    channelName: channelName,
    channelSlug: channelSlug,
    title: title ?? 'News $i',
    body: body ?? 'Testo della news $i',
    createdAt: DateTime(2026).subtract(Duration(minutes: i)),
  );
}

/// News in memoria. Se [gate] è impostato, le pagine successive alla prima
/// restano in attesa finché non si completa.
class FakeNewsRepository implements NewsRepository {
  FakeNewsRepository({List<ChannelNews>? news}) : news = news ?? [];

  List<ChannelNews> news;
  Failure? listError;
  Failure? detailError;
  Failure? createError;
  Failure? updateError;
  Failure? deleteError;
  Completer<void>? gate;

  /// Le news dei canali seguiti (la Home).
  List<ChannelNews> followed = [];
  Failure? followedError;
  Completer<void>? followedGate;
  final followedCalls = <({int offset, int limit})>[];
  final listCalls = <({String channelId, int offset, int limit})>[];
  final createCalls = <Map<String, String>>[];
  final updateCalls = <Map<String, String>>[];
  final deleteCalls = <String>[];

  @override
  Future<List<ChannelNews>> getChannelNews({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    listCalls.add((channelId: channelId, offset: offset, limit: limit));
    if (listError != null) throw listError!;
    if (offset > 0 && gate != null) await gate!.future;
    return news
        .where((n) => n.channelId == channelId)
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<List<ChannelNews>> getFollowedNews({
    required int offset,
    required int limit,
  }) async {
    followedCalls.add((offset: offset, limit: limit));
    if (followedError != null) throw followedError!;
    if (offset > 0 && followedGate != null) await followedGate!.future;
    return followed.skip(offset).take(limit).toList();
  }

  @override
  Future<ChannelNews> getNews(String newsId) async {
    if (detailError != null) throw detailError!;
    return news.firstWhere(
      (n) => n.id == newsId,
      orElse: () => throw const NotFoundFailure(),
    );
  }

  @override
  Future<ChannelNews> createNews({
    required String channelId,
    required String title,
    required String body,
  }) async {
    createCalls.add({'channelId': channelId, 'title': title, 'body': body});
    if (createError != null) throw createError!;
    final created = makeNews(
      100 + createCalls.length,
      channelId: channelId,
      title: title,
      body: body,
    );
    news = [created, ...news];
    return created;
  }

  @override
  Future<ChannelNews> updateNews({
    required String newsId,
    required String title,
    required String body,
  }) async {
    updateCalls.add({'newsId': newsId, 'title': title, 'body': body});
    if (updateError != null) throw updateError!;
    final old = news.firstWhere(
      (n) => n.id == newsId,
      orElse: () => throw const NotFoundFailure(),
    );
    final updated = ChannelNews(
      id: old.id,
      channelId: old.channelId,
      channelName: old.channelName,
      channelSlug: old.channelSlug,
      title: title,
      body: body,
      createdAt: old.createdAt,
    );
    news = [
      for (final n in news)
        if (n.id == newsId) updated else n,
    ];
    return updated;
  }

  @override
  Future<void> deleteNews(String newsId) async {
    deleteCalls.add(newsId);
    if (deleteError != null) throw deleteError!;
    final before = news.length;
    news = news.where((n) => n.id != newsId).toList();
    if (news.length == before) throw const NotFoundFailure();
  }
}
