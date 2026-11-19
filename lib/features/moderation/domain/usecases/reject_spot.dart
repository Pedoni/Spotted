import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';

class RejectSpot {
  const RejectSpot(this._repository);

  final ModerationRepository _repository;

  Future<void> call(String spotId) => _repository.rejectSpot(spotId);
}
