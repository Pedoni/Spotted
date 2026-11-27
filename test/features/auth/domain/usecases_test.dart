import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/auth/domain/repositories/auth_repository.dart';
import 'package:spotted/features/auth/domain/usecases/change_email.dart';
import 'package:spotted/features/auth/domain/usecases/change_password.dart';
import 'package:spotted/features/auth/domain/usecases/check_username_available.dart';
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

  group('CheckUsernameAvailable', () {
    test('controlla in minuscolo e senza spazi', () async {
      when(
        () => repository.isUsernameAvailable('mario_88'),
      ).thenAnswer((_) async => true);

      final free = await CheckUsernameAvailable(repository)(' Mario_88 ');

      expect(free, isTrue);
      verify(() => repository.isUsernameAvailable('mario_88')).called(1);
    });

    test('occupato: false', () async {
      when(
        () => repository.isUsernameAvailable('mario_88'),
      ).thenAnswer((_) async => false);

      expect(await CheckUsernameAvailable(repository)('mario_88'), isFalse);
    });

    test('non valido: false, senza chiedere al repository', () async {
      expect(await CheckUsernameAvailable(repository)('a!'), isFalse);
      expect(await CheckUsernameAvailable(repository)('ab'), isFalse);

      verifyNever(() => repository.isUsernameAvailable(any()));
    });

    test("l'errore del repository passa così com'è", () {
      when(
        () => repository.isUsernameAvailable(any()),
      ).thenThrow(const NetworkFailure());

      expect(
        CheckUsernameAvailable(repository)('mario_88'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('ChangePassword', () {
    void stub() => when(
      () => repository.changePassword(
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async {});

    test('passa le due password al repository', () async {
      stub();

      await ChangePassword(repository)(
        currentPassword: 'vecchia123',
        newPassword: 'nuova12345',
      );

      verify(
        () => repository.changePassword(
          currentPassword: 'vecchia123',
          newPassword: 'nuova12345',
        ),
      ).called(1);
    });

    test('la password attuale vuota non arriva al repository', () {
      expect(
        () => ChangePassword(repository)(
          currentPassword: '',
          newPassword: 'nuova12345',
        ),
        throwsA(const AuthFailure(AuthFailureReason.invalidInput)),
      );
      verifyZeroInteractions(repository);
    });

    test('la nuova password troppo corta non arriva al repository', () {
      expect(
        () => ChangePassword(repository)(
          currentPassword: 'vecchia123',
          newPassword: 'corta',
        ),
        throwsA(const AuthFailure(AuthFailureReason.invalidInput)),
      );
      verifyZeroInteractions(repository);
    });

    test('la nuova password uguale all attuale non arriva al repository', () {
      expect(
        () => ChangePassword(repository)(
          currentPassword: 'stessa12345',
          newPassword: 'stessa12345',
        ),
        throwsA(const AuthFailure(AuthFailureReason.samePassword)),
      );
      verifyZeroInteractions(repository);
    });
  });

  group('ChangeEmail', () {
    test('toglie gli spazi dal nuovo indirizzo', () async {
      when(
        () => repository.changeEmail(
          currentPassword: any(named: 'currentPassword'),
          newEmail: any(named: 'newEmail'),
        ),
      ).thenAnswer((_) async {});

      await ChangeEmail(repository)(
        currentPassword: 'vecchia123',
        newEmail: ' nuova@b.it ',
      );

      verify(
        () => repository.changeEmail(
          currentPassword: 'vecchia123',
          newEmail: 'nuova@b.it',
        ),
      ).called(1);
    });

    test('un indirizzo non valido non arriva al repository', () {
      expect(
        () => ChangeEmail(repository)(
          currentPassword: 'vecchia123',
          newEmail: 'non-una-email',
        ),
        throwsA(const AuthFailure(AuthFailureReason.invalidInput)),
      );
      verifyZeroInteractions(repository);
    });

    test('la password attuale vuota non arriva al repository', () {
      expect(
        () => ChangeEmail(repository)(
          currentPassword: '',
          newEmail: 'nuova@b.it',
        ),
        throwsA(const AuthFailure(AuthFailureReason.invalidInput)),
      );
      verifyZeroInteractions(repository);
    });
  });
}
