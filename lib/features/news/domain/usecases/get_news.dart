import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/domain/repositories/news_repository.dart';

class GetNews {
  const GetNews(this._repository);

  final NewsRepository _repository;

  Future<ChannelNews> call(String newsId) => _repository.getNews(newsId);
}
