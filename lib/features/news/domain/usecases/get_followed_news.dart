import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/domain/repositories/news_repository.dart';

class GetFollowedNews {
  const GetFollowedNews(this._repository);

  final NewsRepository _repository;

  Future<List<ChannelNews>> call({required int offset, required int limit}) {
    return _repository.getFollowedNews(offset: offset, limit: limit);
  }
}
