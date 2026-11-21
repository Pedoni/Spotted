import 'package:spotted/features/moderation/domain/entities/blocked_user.dart';
import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';

class GetBlockedUsers {
  const GetBlockedUsers(this._repository);

  final ModerationRepository _repository;

  Future<List<BlockedUser>> call({
    required String channelId,
    required int offset,
    required int limit,
  }) => _repository.getBlockedUsers(
    channelId: channelId,
    offset: offset,
    limit: limit,
  );
}
