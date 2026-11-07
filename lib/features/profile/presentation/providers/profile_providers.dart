import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:spotted/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/domain/repositories/profile_repository.dart';
import 'package:spotted/features/profile/domain/usecases/get_my_profile.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(
    ProfileRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
Future<Profile> myProfile(Ref ref) {
  return GetMyProfile(ref.watch(profileRepositoryProvider))();
}
