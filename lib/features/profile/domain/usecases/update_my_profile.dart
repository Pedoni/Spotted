import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/domain/profile_validators.dart';
import 'package:spotted/features/profile/domain/repositories/profile_repository.dart';

class UpdateMyProfile {
  const UpdateMyProfile(this._repository);

  final ProfileRepository _repository;

  /// Controlla i dati (nome e cognome obbligatori, data non nel futuro) e li
  /// salva, senza gli spazi ai bordi.
  Future<Profile> call({
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  }) {
    if (!ProfileValidators.isValidName(firstName) ||
        !ProfileValidators.isValidName(lastName) ||
        !ProfileValidators.isValidBirthDate(birthDate)) {
      throw const ValidationFailure();
    }
    return _repository.updateMyProfile(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      birthDate: birthDate == null
          ? null
          : DateTime(birthDate.year, birthDate.month, birthDate.day),
    );
  }
}
