import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/domain/repositories/news_repository.dart';

class GetChannelNews {
  const GetChannelNews(this._repository);

  final NewsRepository _repository;

  Future<List<ChannelNews>> call({
    required String channelId,
    required int offset,
    required int limit,
  }) {
    return _repository.getChannelNews(
      channelId: channelId,
      offset: offset,
      limit: limit,
    );
  }
}
