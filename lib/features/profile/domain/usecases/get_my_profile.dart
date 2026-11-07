import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/domain/repositories/profile_repository.dart';

class GetMyProfile {
  const GetMyProfile(this._repository);

  final ProfileRepository _repository;

  Future<Profile> call() => _repository.getMyProfile();
}
