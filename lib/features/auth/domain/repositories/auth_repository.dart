import 'package:spotted/features/auth/domain/entities/app_user.dart';

/// Contratto di autenticazione. Le implementazioni lanciano un `Failure`.
abstract interface class AuthRepository {
  AppUser? get currentUser;

  /// Emette l'utente corrente subito, poi a ogni cambio di sessione.
  Stream<AppUser?> watchUser();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  });

  Future<void> signOut();

  Future<bool> isUsernameAvailable(String username);
}
