import 'package:spotted/features/spots/domain/entities/spot_with_channel.dart';
import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';

class GetFollowedSpots {
  const GetFollowedSpots(this._repository);

  final SpotsRepository _repository;

  Future<List<SpotWithChannel>> call({
    required int offset,
    required int limit,
  }) {
    return _repository.getFollowedSpots(offset: offset, limit: limit);
  }
}
