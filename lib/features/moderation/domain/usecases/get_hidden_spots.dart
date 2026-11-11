import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';

class GetHiddenSpots {
  const GetHiddenSpots(this._repository);

  final ModerationRepository _repository;

  Future<List<Spot>> call({
    required String channelId,
    required int offset,
    required int limit,
  }) => _repository.getHiddenSpots(
    channelId: channelId,
    offset: offset,
    limit: limit,
  );
}
