import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:spotted/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockDataSource dataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    dataSource = MockDataSource();
    repository = AuthRepositoryImpl(dataSource);
  });

  Future<void> signIn() => repository.signIn(email: 'a@b.it', password: 'x');

  void failSignInWith(Object error) {
    when(
      () => dataSource.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(error);
  }

  group('mapping degli errori', () {
    test('credenziali errate', () {
      failSignInWith(
        const AuthApiException(
          'bad',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );
      expect(
        signIn(),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.reason,
            'reason',
            AuthFailureReason.invalidCredentials,
          ),
        ),
      );
    });

    test('email già registrata', () {
      failSignInWith(
        const AuthApiException(
          'exists',
          statusCode: '422',
          code: 'user_already_exists',
        ),
      );
      expect(
        signIn(),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.reason,
            'reason',
            AuthFailureReason.emailTaken,
          ),
        ),
      );
    });

    test('errore del trigger sul profilo = username occupato', () {
      failSignInWith(
        const AuthApiException(
          'Database error saving new user',
          statusCode: '500',
          code: 'unexpected_failure',
        ),
      );
      expect(
        signIn(),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.reason,
            'reason',
            AuthFailureReason.usernameTaken,
          ),
        ),
      );
    });

    test('errore di rete', () {
      failSignInWith(AuthRetryableFetchException(message: 'offline'));
      expect(signIn(), throwsA(isA<NetworkFailure>()));
    });

    test('errore sconosciuto', () {
      failSignInWith(Exception('boom'));
      expect(signIn(), throwsA(isA<UnknownFailure>()));
    });
  });

  test('currentUser mappa l utente Supabase', () {
    when(() => dataSource.currentUser).thenReturn(
      const User(
        id: 'u1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
        email: 'a@b.it',
      ),
    );
    expect(repository.currentUser?.id, 'u1');
    expect(repository.currentUser?.email, 'a@b.it');
  });

  test('currentUser è null senza sessione', () {
    when(() => dataSource.currentUser).thenReturn(null);
    expect(repository.currentUser, isNull);
  });

  test('isUsernameAvailable inoltra al datasource', () async {
    when(
      () => dataSource.isUsernameAvailable('mario'),
    ).thenAnswer((_) async => true);
    expect(await repository.isUsernameAvailable('mario'), isTrue);
  });
}
