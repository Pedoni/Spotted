import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/auth/domain/auth_validators.dart';
import 'package:spotted/features/auth/domain/repositories/auth_repository.dart';

class SignUp {
  const SignUp(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    if (!AuthValidators.isValidEmail(email) ||
        !AuthValidators.isValidUsername(username) ||
        !AuthValidators.isValidPassword(password) ||
        !AuthValidators.isValidName(firstName) ||
        !AuthValidators.isValidName(lastName)) {
      throw const AuthFailure(AuthFailureReason.invalidInput);
    }

    // Il trigger del database salva lo username in minuscolo.
    final normalizedUsername = username.trim().toLowerCase();

    // Controllo prima del signup: se lo username è occupato il trigger
    // farebbe fallire la registrazione con un errore generico.
    if (!await _repository.isUsernameAvailable(normalizedUsername)) {
      throw const AuthFailure(AuthFailureReason.usernameTaken);
    }

    await _repository.signUp(
      email: email.trim(),
      password: password,
      username: normalizedUsername,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    );
  }
}
