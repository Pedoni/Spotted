import 'package:spotted/features/auth/domain/auth_validators.dart';
import 'package:spotted/features/auth/domain/repositories/auth_repository.dart';

/// Dice se uno username è libero. Il database salva gli username in
/// minuscolo, quindi si controlla in minuscolo. Uno username non valido non si
/// cerca nemmeno (la risposta è `false`: non si può usare).
class CheckUsernameAvailable {
  const CheckUsernameAvailable(this._repository);

  final AuthRepository _repository;

  Future<bool> call(String username) async {
    if (!AuthValidators.isValidUsername(username)) return false;
    return _repository.isUsernameAvailable(username.trim().toLowerCase());
  }
}
