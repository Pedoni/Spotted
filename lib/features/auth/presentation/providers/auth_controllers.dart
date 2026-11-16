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

  /// Esce dall'account. Restituisce l'errore se non ci riesce, `null` se va
  /// bene. Chi chiama usa il valore restituito e non rilegge lo stato: quando
  /// l'uscita riesce il router porta all'accesso e la pagina da cui si chiama
  /// sparisce, quindi il suo `ref` non si può più usare.
  Future<Object?> submit() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(signOutUseCaseProvider)(),
    );
    if (ref.mounted) state = result;
    return result.error;
  }
}
