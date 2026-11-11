import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';

class IsChannelOwner {
  const IsChannelOwner(this._repository);

  final ModerationRepository _repository;

  Future<bool> call(String channelId) => _repository.isChannelOwner(channelId);
}
