import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._dataSource);

  final ProfileRemoteDataSource _dataSource;

  @override
  Future<Profile> getMyProfile() => guardFailures(_dataSource.getMyProfile);
}
