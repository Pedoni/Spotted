import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';

class GetChannelSpots {
  const GetChannelSpots(this._repository);

  final SpotsRepository _repository;

  Future<List<Spot>> call({
    required String channelId,
    required int offset,
    required int limit,
  }) {
    return _repository.getChannelSpots(
      channelId: channelId,
      offset: offset,
      limit: limit,
    );
  }
}
