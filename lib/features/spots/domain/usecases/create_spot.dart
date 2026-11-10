import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';

class CreateSpot {
  const CreateSpot(this._repository);

  final SpotsRepository _repository;

  /// Valida titolo e testo (togliendo gli spazi ai bordi) e pubblica.
  Future<Spot> call({
    required String channelId,
    required String title,
    required String content,
  }) async {
    if (!SpotValidators.isValidTitle(title) ||
        !SpotValidators.isValidContent(content)) {
      throw const ValidationFailure();
    }
    return _repository.createSpot(
      channelId: channelId,
      title: title.trim(),
      content: content.trim(),
    );
  }
}
