import 'dart:async';

import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/auth/domain/entities/app_user.dart';
import 'package:spotted/features/auth/domain/repositories/auth_repository.dart';

/// Repository in memoria per i widget test.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user});

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? user;

  int signOutCalls = 0;
  Failure? signInError;
  Failure? signUpError;
  Failure? signOutError;
  Completer<void>? signOutGate;

  /// Come Supabase: l'utente risulta uscito (evento) prima che la chiamata
  /// `signOut` finisca di rispondere.
  bool signOutEventFirst = false;
  Set<String> takenUsernames = {};
  Failure? availabilityError;

  /// Se è impostato, il controllo dello username aspetta che si completi.
  Completer<void>? availabilityGate;
  final availabilityCalls = <String>[];

  /// La password dell'utente: chi cambia password o email deve dare questa.
  String password = 'vecchiapassword';
  Failure? changeError;

  /// Se è impostato, il cambio di password o email aspetta che si completi.
  Completer<void>? changeGate;
  final passwordChanges = <({String current, String next})>[];
  final emailChanges = <({String current, String email})>[];

  final signInCalls = <({String email, String password})>[];
  final signUpCalls = <Map<String, String>>[];

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> watchUser() async* {
    yield user;
    yield* _controller.stream;
  }

  void _setUser(AppUser? value) {
    user = value;
    _controller.add(value);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls.add((email: email, password: password));
    if (signInError != null) throw signInError!;
    _setUser(AppUser(id: '1', email: email));
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    signUpCalls.add({
      'email': email,
      'password': password,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
    });
    if (signUpError != null) throw signUpError!;
    _setUser(AppUser(id: '1', email: email));
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutEventFirst) _setUser(null);
    if (signOutGate != null) await signOutGate!.future;
    if (signOutError != null) throw signOutError!;
    if (!signOutEventFirst) _setUser(null);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordChanges.add((current: currentPassword, next: newPassword));
    if (changeGate != null) await changeGate!.future;
    if (changeError != null) throw changeError!;
    if (currentPassword != password) {
      throw const AuthFailure(AuthFailureReason.wrongPassword);
    }
    password = newPassword;
  }

  /// Come Supabase: l'email non cambia subito, resta quella vecchia con il
  /// nuovo indirizzo in attesa di conferma.
  @override
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    emailChanges.add((current: currentPassword, email: newEmail));
    if (changeGate != null) await changeGate!.future;
    if (changeError != null) throw changeError!;
    if (currentPassword != password) {
      throw const AuthFailure(AuthFailureReason.wrongPassword);
    }
    final current = user!;
    _setUser(
      AppUser(id: current.id, email: current.email, pendingEmail: newEmail),
    );
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    availabilityCalls.add(username);
    if (availabilityGate != null) await availabilityGate!.future;
    if (availabilityError != null) throw availabilityError!;
    return !takenUsernames.contains(username);
  }
}
