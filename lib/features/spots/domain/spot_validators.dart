abstract final class SpotValidators {
  static const maxTitleLength = 100;
  static const maxContentLength = 2000;

  static bool isValidTitle(String value) {
    final length = value.trim().length;
    return length >= 1 && length <= maxTitleLength;
  }

  static bool isValidContent(String value) {
    final length = value.trim().length;
    return length >= 1 && length <= maxContentLength;
  }
}
