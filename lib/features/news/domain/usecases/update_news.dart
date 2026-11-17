import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/domain/news_validators.dart';
import 'package:spotted/features/news/domain/repositories/news_repository.dart';

class UpdateNews {
  const UpdateNews(this._repository);

  final NewsRepository _repository;

  /// Valida titolo e testo (togliendo gli spazi ai bordi) e salva.
  Future<ChannelNews> call({
    required String newsId,
    required String title,
    required String body,
  }) async {
    if (!NewsValidators.isValidTitle(title) ||
        !NewsValidators.isValidBody(body)) {
      throw const ValidationFailure();
    }
    return _repository.updateNews(
      newsId: newsId,
      title: title.trim(),
      body: body.trim(),
    );
  }
}
