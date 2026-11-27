import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/auth/domain/auth_validators.dart';
import 'package:spotted/features/auth/domain/repositories/auth_repository.dart';

class ChangePassword {
  const ChangePassword(this._repository);

  final AuthRepository _repository;

  /// Controlla le regole prima di chiamare il server: la password attuale non
  /// è vuota, la nuova rispetta le regole di sempre ed è diversa da quella
  /// attuale.
  Future<void> call({
    required String currentPassword,
    required String newPassword,
  }) {
    if (currentPassword.isEmpty ||
        !AuthValidators.isValidPassword(newPassword)) {
      throw const AuthFailure(AuthFailureReason.invalidInput);
    }
    if (newPassword == currentPassword) {
      throw const AuthFailure(AuthFailureReason.samePassword);
    }
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
