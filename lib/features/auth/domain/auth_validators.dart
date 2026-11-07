/// Regole di validazione condivise da UI e use case.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _username = RegExp(r'^[a-zA-Z0-9_]{3,30}$');

  static const minPasswordLength = 8;
  static const maxNameLength = 50;

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());

  static bool isValidUsername(String value) => _username.hasMatch(value.trim());

  static bool isValidPassword(String value) =>
      value.length >= minPasswordLength;

  static bool isValidName(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxNameLength;
  }
}
