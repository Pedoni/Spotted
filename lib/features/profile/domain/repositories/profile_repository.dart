import 'package:spotted/features/profile/domain/entities/profile.dart';

abstract interface class ProfileRepository {
  /// Profilo completo dell'utente loggato.
  Future<Profile> getMyProfile();

  /// Cambia nome, cognome e data di nascita (lo username non si cambia) e
  /// restituisce il profilo aggiornato. `ValidationFailure` se i dati non
  /// valgono.
  Future<Profile> updateMyProfile({
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  });
}
