import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';

class UnblockChannelUser {
  const UnblockChannelUser(this._repository);

  final ModerationRepository _repository;

  Future<void> call(String blockId) => _repository.unblockChannelUser(blockId);
}
