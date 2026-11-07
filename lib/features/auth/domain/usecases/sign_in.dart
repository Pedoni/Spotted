import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/auth/domain/auth_validators.dart';
import 'package:spotted/features/auth/domain/repositories/auth_repository.dart';

class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email, required String password}) {
    if (!AuthValidators.isValidEmail(email) || password.isEmpty) {
      throw const AuthFailure(AuthFailureReason.invalidInput);
    }
    return _repository.signIn(email: email.trim(), password: password);
  }
}
