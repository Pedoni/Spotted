import 'package:spotted/features/auth/domain/auth_validators.dart';

/// Regole sui dati personali, uguali a quelle del database.
abstract final class ProfileValidators {
  /// Nessuno è nato prima: una data più vecchia è un errore di battitura.
  static final earliestBirthDate = DateTime(1900);

  static bool isValidName(String value) => AuthValidators.isValidName(value);

  /// Facoltativa; se c'è, non nel futuro e non prima del 1900. [today] solo
  /// per i test.
  static bool isValidBirthDate(DateTime? value, {DateTime? today}) {
    if (value == null) return true;
    final now = today ?? DateTime.now();
    final day = DateTime(value.year, value.month, value.day);
    final last = DateTime(now.year, now.month, now.day);
    return !day.isBefore(earliestBirthDate) && !day.isAfter(last);
  }
}
