import 'dart:io';

import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:spotted/features/auth/domain/entities/app_user.dart';
import 'package:spotted/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  AppUser? get currentUser => _toUser(_dataSource.currentUser);

  @override
  Stream<AppUser?> watchUser() async* {
    yield currentUser;
    yield* _dataSource.authStateChanges
        .map((state) => _toUser(state.session?.user))
        .distinct();
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(
      () => _dataSource.signIn(email: email, password: password),
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) {
    return _guard(
      () => _dataSource.signUp(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }

  @override
  Future<void> signOut() => _guard(_dataSource.signOut);

  @override
  Future<bool> isUsernameAvailable(String username) {
    return _guard(() => _dataSource.isUsernameAvailable(username));
  }

  AppUser? _toUser(User? user) {
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } on AuthRetryableFetchException {
      throw const NetworkFailure();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on SocketException {
      throw const NetworkFailure();
    } on Exception catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  AuthFailure _mapAuthException(AuthException e) {
    final reason = switch (e.code) {
      'invalid_credentials' => AuthFailureReason.invalidCredentials,
      'user_already_exists' || 'email_exists' => AuthFailureReason.emailTaken,
      'weak_password' => AuthFailureReason.weakPassword,
      _ when e.message.contains('Database error saving new user') =>
        AuthFailureReason.usernameTaken,
      _ => AuthFailureReason.unknown,
    };
    return AuthFailure(reason, e.message);
  }
}
