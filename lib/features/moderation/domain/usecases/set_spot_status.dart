import 'package:spotted/features/moderation/domain/entities/moderation_status.dart';
import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';

class SetSpotStatus {
  const SetSpotStatus(this._repository);

  final ModerationRepository _repository;

  Future<void> call(String spotId, ModerationStatus status) =>
      _repository.setSpotStatus(spotId, status);
}
