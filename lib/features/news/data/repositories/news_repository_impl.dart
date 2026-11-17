import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/news/data/datasources/news_remote_data_source.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/domain/repositories/news_repository.dart';

class NewsRepositoryImpl implements NewsRepository {
  const NewsRepositoryImpl(this._dataSource);

  final NewsRemoteDataSource _dataSource;

  @override
  Future<List<ChannelNews>> getChannelNews({
    required String channelId,
    required int offset,
    required int limit,
  }) {
    return guardFailures(
      () => _dataSource.getChannelNews(
        channelId: channelId,
        offset: offset,
        limit: limit,
      ),
    );
  }

  @override
  Future<List<ChannelNews>> getFollowedNews({
    required int offset,
    required int limit,
  }) {
    return guardFailures(
      () => _dataSource.getFollowedNews(offset: offset, limit: limit),
    );
  }

  @override
  Future<ChannelNews> getNews(String newsId) {
    return guardFailures(() => _dataSource.getNews(newsId));
  }

  @override
  Future<ChannelNews> createNews({
    required String channelId,
    required String title,
    required String body,
  }) {
    return guardFailures(
      () => _dataSource.createNews(
        channelId: channelId,
        title: title,
        body: body,
      ),
    );
  }

  @override
  Future<ChannelNews> updateNews({
    required String newsId,
    required String title,
    required String body,
  }) {
    return guardFailures(
      () => _dataSource.updateNews(newsId: newsId, title: title, body: body),
    );
  }

  @override
  Future<void> deleteNews(String newsId) {
    return guardFailures(() => _dataSource.deleteNews(newsId));
  }
}
