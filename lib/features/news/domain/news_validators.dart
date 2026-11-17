/// Le regole di titolo e testo di una news (le stesse del database).
abstract final class NewsValidators {
  static const maxTitleLength = 100;
  static const maxBodyLength = 2000;

  static bool isValidTitle(String value) {
    final length = value.trim().length;
    return length >= 1 && length <= maxTitleLength;
  }

  static bool isValidBody(String value) {
    final length = value.trim().length;
    return length >= 1 && length <= maxBodyLength;
  }
}
