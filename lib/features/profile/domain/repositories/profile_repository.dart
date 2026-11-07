import 'package:spotted/features/profile/domain/entities/profile.dart';

abstract interface class ProfileRepository {
  /// Profilo completo dell'utente loggato.
  Future<Profile> getMyProfile();
}
