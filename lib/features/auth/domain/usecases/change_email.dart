import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/auth/domain/auth_validators.dart';
import 'package:spotted/features/auth/domain/repositories/auth_repository.dart';

class ChangeEmail {
  const ChangeEmail(this._repository);

  final AuthRepository _repository;

  /// Controlla le regole prima di chiamare il server: la password attuale non
  /// è vuota e la nuova email è valida (senza spazi ai bordi).
  Future<void> call({
    required String currentPassword,
    required String newEmail,
  }) {
    if (currentPassword.isEmpty || !AuthValidators.isValidEmail(newEmail)) {
      throw const AuthFailure(AuthFailureReason.invalidInput);
    }
    return _repository.changeEmail(
      currentPassword: currentPassword,
      newEmail: newEmail.trim(),
    );
  }
}
