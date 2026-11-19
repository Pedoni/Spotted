import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';

class CreateSpot {
  const CreateSpot(this._repository);

  final SpotsRepository _repository;

  /// Valida titolo e testo (togliendo gli spazi ai bordi) e invia lo spot.
  /// [tags] solo per il proprietario, che pubblica subito.
  Future<Spot> call({
    required String channelId,
    required String title,
    required String content,
    List<String>? tags,
  }) async {
    if (!SpotValidators.isValidTitle(title) ||
        !SpotValidators.isValidContent(content) ||
        (tags != null && !SpotValidators.isValidTagCount(tags.length))) {
      throw const ValidationFailure();
    }
    return _repository.createSpot(
      channelId: channelId,
      title: title.trim(),
      content: content.trim(),
      tags: tags,
    );
  }
}
