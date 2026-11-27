import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';

class GetPendingSpots {
  const GetPendingSpots(this._repository);

  final ModerationRepository _repository;

  Future<List<Spot>> call({
    required String channelId,
    required int offset,
    required int limit,
  }) => _repository.getPendingSpots(
    channelId: channelId,
    offset: offset,
    limit: limit,
  );
}
