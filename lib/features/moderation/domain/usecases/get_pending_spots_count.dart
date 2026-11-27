import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';

class GetPendingSpotsCount {
  const GetPendingSpotsCount(this._repository);

  final ModerationRepository _repository;

  Future<int> call(String channelId) =>
      _repository.getPendingSpotsCount(channelId);
}
