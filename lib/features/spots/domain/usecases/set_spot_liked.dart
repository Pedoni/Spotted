import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';

class SetSpotLiked {
  const SetSpotLiked(this._repository);

  final SpotsRepository _repository;

  Future<void> call(String spotId, {required bool liked}) {
    return _repository.setSpotLiked(spotId, liked: liked);
  }
}
