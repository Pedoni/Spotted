import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:spotted/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/domain/repositories/profile_repository.dart';
import 'package:spotted/features/profile/domain/usecases/get_my_profile.dart';
import 'package:spotted/features/profile/domain/usecases/update_my_profile.dart';

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

@riverpod
UpdateMyProfile updateMyProfileUseCase(Ref ref) {
  return UpdateMyProfile(ref.watch(profileRepositoryProvider));
}

/// Salva i dati personali: `AsyncLoading` mentre è in corso, `AsyncError`
/// (con un `Failure`) se fallisce. Al successo ricarica il profilo che si vede.
@riverpod
class EditProfileController extends _$EditProfileController {
  @override
  FutureOr<void> build() {}

  /// `true` se i dati sono stati salvati, `false` se fallisce (l'errore è in
  /// `state`).
  Future<bool> submit({
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(updateMyProfileUseCaseProvider)(
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
      ),
    );
    if (!ref.mounted) return !result.hasError;
    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return false;
    }
    state = const AsyncData(null);
    ref.invalidate(myProfileProvider);
    return true;
  }
}
