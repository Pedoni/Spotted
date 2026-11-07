import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/auth/domain/repositories/auth_repository.dart';
import 'package:spotted/features/auth/domain/usecases/sign_in.dart';
import 'package:spotted/features/auth/domain/usecases/sign_up.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  group('SignIn', () {
    test('rifiuta input non validi senza chiamare il repository', () {
      final signIn = SignIn(repository);
      expect(
        () => signIn(email: 'no', password: 'x'),
        throwsA(const AuthFailure(AuthFailureReason.invalidInput)),
      );
      verifyZeroInteractions(repository);
    });

    test('toglie gli spazi dall email', () async {
      when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});

      await SignIn(repository)(email: ' a@b.it ', password: 'secret');

      verify(
        () => repository.signIn(email: 'a@b.it', password: 'secret'),
      ).called(1);
    });
  });

  group('SignUp', () {
    Future<void> call(SignUp useCase, {String username = 'Mario_88'}) {
      return useCase(
        email: ' a@b.it ',
        password: '12345678',
        username: username,
        firstName: ' Mario ',
        lastName: 'Rossi',
      );
    }

    test('normalizza i dati e registra', () async {
      when(
        () => repository.isUsernameAvailable('mario_88'),
      ).thenAnswer((_) async => true);
      when(
        () => repository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          username: any(named: 'username'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      ).thenAnswer((_) async {});

      await call(SignUp(repository));

      verify(
        () => repository.signUp(
          email: 'a@b.it',
          password: '12345678',
          username: 'mario_88',
          firstName: 'Mario',
          lastName: 'Rossi',
        ),
      ).called(1);
    });

    test('username occupato: errore e nessun signup', () async {
      when(
        () => repository.isUsernameAvailable('mario_88'),
      ).thenAnswer((_) async => false);

      await expectLater(
        call(SignUp(repository)),
        throwsA(const AuthFailure(AuthFailureReason.usernameTaken)),
      );
      verifyNever(
        () => repository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          username: any(named: 'username'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      );
    });

    test('username non valido: errore di input', () {
      expect(
        call(SignUp(repository), username: 'a!'),
        throwsA(const AuthFailure(AuthFailureReason.invalidInput)),
      );
    });
  });
}
