import 'package:spotted/features/spots/domain/entities/spot_with_channel.dart';
import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';

class GetMySpots {
  const GetMySpots(this._repository);

  final SpotsRepository _repository;

  Future<List<SpotWithChannel>> call({
    required int offset,
    required int limit,
  }) {
    return _repository.getMySpots(offset: offset, limit: limit);
  }
}
