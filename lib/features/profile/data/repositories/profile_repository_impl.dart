import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._dataSource);

  final ProfileRemoteDataSource _dataSource;

  @override
  Future<Profile> getMyProfile() => guardFailures(_dataSource.getMyProfile);

  @override
  Future<Profile> updateMyProfile({
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  }) {
    return guardFailures(
      () => _dataSource.updateMyProfile(
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
      ),
    );
  }
}
