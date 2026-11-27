import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/profile/domain/profile_validators.dart';
import 'package:spotted/features/profile/domain/usecases/update_my_profile.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeProfileRepository repository;
  late UpdateMyProfile updateMyProfile;

  setUp(() {
    repository = FakeProfileRepository();
    updateMyProfile = UpdateMyProfile(repository);
  });

  test('toglie gli spazi ai bordi di nome e cognome', () async {
    await updateMyProfile(firstName: '  Mario ', lastName: ' Rossi  ');

    final call = repository.updateCalls.single;
    expect(call.firstName, 'Mario');
    expect(call.lastName, 'Rossi');
    expect(call.birthDate, isNull);
  });

  test('la data di nascita resta un giorno, senza ora', () async {
    await updateMyProfile(
      firstName: 'Mario',
      lastName: 'Rossi',
      birthDate: DateTime(2000, 1, 31, 15, 30),
    );

    expect(repository.updateCalls.single.birthDate, DateTime(2000, 1, 31));
  });

  test('nome vuoto o di soli spazi: ValidationFailure, niente richiesta', () {
    expect(
      () => updateMyProfile(firstName: '   ', lastName: 'Rossi'),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => updateMyProfile(firstName: 'Mario', lastName: ''),
      throwsA(isA<ValidationFailure>()),
    );
    expect(repository.updateCalls, isEmpty);
  });

  test('un nome più lungo di 50 caratteri non va', () {
    expect(
      () => updateMyProfile(firstName: 'a' * 51, lastName: 'Rossi'),
      throwsA(isA<ValidationFailure>()),
    );
    expect(updateMyProfile(firstName: 'a' * 50, lastName: 'Rossi'), completes);
  });

  test('una data nel futuro non va', () {
    expect(
      () => updateMyProfile(
        firstName: 'Mario',
        lastName: 'Rossi',
        birthDate: DateTime.now().add(const Duration(days: 2)),
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(repository.updateCalls, isEmpty);
  });

  test("l'errore del repository passa così com'è", () {
    repository.updateError = const PermissionFailure();

    expect(
      () => updateMyProfile(firstName: 'Mario', lastName: 'Rossi'),
      throwsA(isA<PermissionFailure>()),
    );
  });

  group('ProfileValidators.isValidBirthDate', () {
    final today = DateTime(2026, 6, 15);

    test('senza data va bene', () {
      expect(ProfileValidators.isValidBirthDate(null, today: today), isTrue);
    });

    test('oggi sì, domani no', () {
      expect(
        ProfileValidators.isValidBirthDate(DateTime(2026, 6, 15), today: today),
        isTrue,
      );
      expect(
        ProfileValidators.isValidBirthDate(DateTime(2026, 6, 16), today: today),
        isFalse,
      );
    });

    test('dal 1900 in poi', () {
      expect(
        ProfileValidators.isValidBirthDate(DateTime(1900), today: today),
        isTrue,
      );
      expect(
        ProfileValidators.isValidBirthDate(
          DateTime(1899, 12, 31),
          today: today,
        ),
        isFalse,
      );
    });
  });
}
