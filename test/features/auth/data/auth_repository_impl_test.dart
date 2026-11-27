import 'dart:async';
import 'dart:io';

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

    test('timeout della richiesta', () {
      failSignInWith(TimeoutException('lento'));
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

  group('cambio di password ed email', () {
    const wrongPassword = AuthApiException(
      'bad',
      statusCode: '400',
      code: 'invalid_credentials',
    );

    void verifyOk() =>
        when(() => dataSource.verifyPassword(any())).thenAnswer((_) async {});

    test('password: controlla la attuale e poi aggiorna', () async {
      verifyOk();
      when(
        () => dataSource.updatePassword(any()),
      ).thenAnswer((_) async {});

      await repository.changePassword(
        currentPassword: 'vecchia',
        newPassword: 'nuova12345',
      );

      verifyInOrder([
        () => dataSource.verifyPassword('vecchia'),
        () => dataSource.updatePassword('nuova12345'),
      ]);
    });

    test('password attuale sbagliata: messaggio suo, niente aggiornamento', () {
      when(() => dataSource.verifyPassword(any())).thenThrow(wrongPassword);

      expect(
        repository.changePassword(
          currentPassword: 'sbagliata',
          newPassword: 'nuova12345',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.reason,
            'reason',
            AuthFailureReason.wrongPassword,
          ),
        ),
      );
      verifyNever(() => dataSource.updatePassword(any()));
    });

    test('nuova password uguale all attuale (same_password)', () {
      verifyOk();
      when(() => dataSource.updatePassword(any())).thenThrow(
        const AuthApiException(
          'same',
          statusCode: '422',
          code: 'same_password',
        ),
      );

      expect(
        repository.changePassword(
          currentPassword: 'vecchia',
          newPassword: 'nuova12345',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.reason,
            'reason',
            AuthFailureReason.samePassword,
          ),
        ),
      );
    });

    test('nuova password troppo debole (weak_password)', () {
      verifyOk();
      when(() => dataSource.updatePassword(any())).thenThrow(
        const AuthApiException(
          'weak',
          statusCode: '422',
          code: 'weak_password',
        ),
      );

      expect(
        repository.changePassword(
          currentPassword: 'vecchia',
          newPassword: 'nuova12345',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.reason,
            'reason',
            AuthFailureReason.weakPassword,
          ),
        ),
      );
    });

    test('email: controlla la password e poi chiede il cambio', () async {
      verifyOk();
      when(() => dataSource.updateEmail(any())).thenAnswer((_) async {});

      await repository.changeEmail(
        currentPassword: 'vecchia',
        newEmail: 'nuova@b.it',
      );

      verifyInOrder([
        () => dataSource.verifyPassword('vecchia'),
        () => dataSource.updateEmail('nuova@b.it'),
      ]);
    });

    test('email: password sbagliata, niente richiesta', () {
      when(() => dataSource.verifyPassword(any())).thenThrow(wrongPassword);

      expect(
        repository.changeEmail(
          currentPassword: 'sbagliata',
          newEmail: 'nuova@b.it',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.reason,
            'reason',
            AuthFailureReason.wrongPassword,
          ),
        ),
      );
      verifyNever(() => dataSource.updateEmail(any()));
    });

    test('email: indirizzo già usato (email_exists)', () {
      verifyOk();
      when(() => dataSource.updateEmail(any())).thenThrow(
        const AuthApiException(
          'exists',
          statusCode: '422',
          code: 'email_exists',
        ),
      );

      expect(
        repository.changeEmail(
          currentPassword: 'vecchia',
          newEmail: 'nuova@b.it',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.reason,
            'reason',
            AuthFailureReason.emailTaken,
          ),
        ),
      );
    });

    test('email: indirizzo non valido (email_address_invalid)', () {
      verifyOk();
      when(() => dataSource.updateEmail(any())).thenThrow(
        const AuthApiException(
          'invalid',
          statusCode: '400',
          code: 'email_address_invalid',
        ),
      );

      expect(
        repository.changeEmail(
          currentPassword: 'vecchia',
          newEmail: 'nuova@b.it',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.reason,
            'reason',
            AuthFailureReason.invalidInput,
          ),
        ),
      );
    });

    test('errore di rete durante il cambio', () {
      when(
        () => dataSource.verifyPassword(any()),
      ).thenThrow(const SocketException('giù'));

      expect(
        repository.changePassword(
          currentPassword: 'vecchia',
          newPassword: 'nuova12345',
        ),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  test('currentUser porta l email in attesa di conferma', () {
    when(() => dataSource.currentUser).thenReturn(
      const User(
        id: 'u1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
        email: 'a@b.it',
        newEmail: 'nuova@b.it',
      ),
    );

    expect(repository.currentUser?.email, 'a@b.it');
    expect(repository.currentUser?.pendingEmail, 'nuova@b.it');
  });

  test('currentUser senza cambio in corso non ha email in attesa', () {
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

    expect(repository.currentUser?.pendingEmail, isNull);
  });
}
