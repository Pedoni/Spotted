import 'package:spotted/features/news/domain/repositories/news_repository.dart';

class DeleteNews {
  const DeleteNews(this._repository);

  final NewsRepository _repository;

  Future<void> call(String newsId) => _repository.deleteNews(newsId);
}
