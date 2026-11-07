import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';

part 'auth_controllers.g.dart';

/// Stato dell'operazione di login: `AsyncLoading` mentre è in corso,
/// `AsyncError` (con un `Failure`) se fallisce.
@riverpod
class SignInController extends _$SignInController {
  @override
  FutureOr<void> build() {}

  Future<void> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(signInUseCaseProvider)(email: email, password: password),
    );
    // Al successo il router cambia pagina e il controller viene eliminato.
    if (ref.mounted) state = result;
  }
}

@riverpod
class SignUpController extends _$SignUpController {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(signUpUseCaseProvider)(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
      ),
    );
    if (ref.mounted) state = result;
  }
}

@riverpod
class SignOutController extends _$SignOutController {
  @override
  FutureOr<void> build() {}

  Future<void> submit() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(signOutUseCaseProvider)(),
    );
    if (ref.mounted) state = result;
  }
}
