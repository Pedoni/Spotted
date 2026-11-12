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
  Set<String> takenUsernames = {};

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
    _setUser(null);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async =>
      !takenUsernames.contains(username);
}
