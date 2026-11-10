import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';

class GetSpot {
  const GetSpot(this._repository);

  final SpotsRepository _repository;

  Future<Spot> call(String spotId) => _repository.getSpot(spotId);
}
