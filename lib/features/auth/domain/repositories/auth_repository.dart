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

  /// Cambia la password. Chiede quella attuale (riaccede per controllarla):
  /// `AuthFailure(wrongPassword)` se è sbagliata, `AuthFailure(samePassword)`
  /// se la nuova è uguale.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Chiede di cambiare l'email. Chiede la password attuale. Supabase manda
  /// una conferma: l'indirizzo cambia solo dopo (`AppUser.pendingEmail` lo
  /// dice nel frattempo). `AuthFailure(emailTaken)` se esiste già un account
  /// con quell'email.
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  });

  Future<bool> isUsernameAvailable(String username);
}
