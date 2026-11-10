import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';

class DeleteSpot {
  const DeleteSpot(this._repository);

  final SpotsRepository _repository;

  Future<void> call(String spotId) => _repository.deleteSpot(spotId);
}
