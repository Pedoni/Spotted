import 'package:spotted/features/moderation/domain/entities/spot_author.dart';
import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';

class GetSpotAuthor {
  const GetSpotAuthor(this._repository);

  final ModerationRepository _repository;

  Future<SpotAuthor> call(String spotId) => _repository.getSpotAuthor(spotId);
}
