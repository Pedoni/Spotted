import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';

class ApproveSpot {
  const ApproveSpot(this._repository);

  final ModerationRepository _repository;

  /// Controlla che i tag siano da 1 a 3 prima di chiamare il database, che
  /// controlla anche che esistano e valgano per il canale.
  Future<void> call(String spotId, List<String> tags) {
    if (!SpotValidators.isValidTagCount(tags.length)) {
      throw const ValidationFailure();
    }
    return _repository.approveSpot(spotId, tags);
  }
}
