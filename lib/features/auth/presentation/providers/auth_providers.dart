import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:spotted/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:spotted/features/auth/domain/entities/app_user.dart';
import 'package:spotted/features/auth/domain/repositories/auth_repository.dart';
import 'package:spotted/features/auth/domain/usecases/change_email.dart';
import 'package:spotted/features/auth/domain/usecases/change_password.dart';
import 'package:spotted/features/auth/domain/usecases/check_username_available.dart';
import 'package:spotted/features/auth/domain/usecases/sign_in.dart';
import 'package:spotted/features/auth/domain/usecases/sign_out.dart';
import 'package:spotted/features/auth/domain/usecases/sign_up.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@Riverpod(keepAlive: true)
Stream<AppUser?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).watchUser();
}

@riverpod
SignIn signInUseCase(Ref ref) => SignIn(ref.watch(authRepositoryProvider));

@riverpod
ChangePassword changePasswordUseCase(Ref ref) {
  return ChangePassword(ref.watch(authRepositoryProvider));
}

@riverpod
ChangeEmail changeEmailUseCase(Ref ref) {
  return ChangeEmail(ref.watch(authRepositoryProvider));
}

@riverpod
SignUp signUpUseCase(Ref ref) => SignUp(ref.watch(authRepositoryProvider));

@riverpod
CheckUsernameAvailable checkUsernameAvailableUseCase(Ref ref) {
  return CheckUsernameAvailable(ref.watch(authRepositoryProvider));
}

@riverpod
SignOut signOutUseCase(Ref ref) => SignOut(ref.watch(authRepositoryProvider));
