import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/domain/news_validators.dart';
import 'package:spotted/features/news/domain/repositories/news_repository.dart';

class CreateNews {
  const CreateNews(this._repository);

  final NewsRepository _repository;

  /// Valida titolo e testo (togliendo gli spazi ai bordi) e salva.
  Future<ChannelNews> call({
    required String channelId,
    required String title,
    required String body,
  }) async {
    if (!NewsValidators.isValidTitle(title) ||
        !NewsValidators.isValidBody(body)) {
      throw const ValidationFailure();
    }
    return _repository.createNews(
      channelId: channelId,
      title: title.trim(),
      body: body.trim(),
    );
  }
}
