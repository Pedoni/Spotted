import 'package:supabase_flutter/supabase_flutter.dart';

/// Accesso diretto a Supabase Auth e alla tabella `profiles`.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Username e nomi passano nei metadata: li legge il trigger
  /// `handle_new_user` per creare il profilo.
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
      },
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Controlla la password attuale accedendo di nuovo con l'email dell'utente.
  /// Lancia `AuthException` (`invalid_credentials`) se è sbagliata.
  Future<void> verifyPassword(String password) async {
    final email = currentUser?.email;
    if (email == null) throw AuthSessionMissingException();
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Supabase scrive all'indirizzo nuovo (e, secondo le impostazioni del
  /// progetto, anche al vecchio) per la conferma: finché non è confermato
  /// l'indirizzo valido resta il vecchio.
  Future<void> updateEmail(String newEmail) {
    return _client.auth.updateUser(UserAttributes(email: newEmail));
  }

  Future<bool> isUsernameAvailable(String username) async {
    final row = await _client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return row == null;
  }
}
