abstract final class MessageValidators {
  static const maxLength = 5000;

  static bool isValid(String value) {
    final length = value.trim().length;
    return length >= 1 && length <= maxLength;
  }
}
