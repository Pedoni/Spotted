abstract final class CommentValidators {
  static const maxLength = 500;

  static bool isValid(String value) {
    final length = value.trim().length;
    return length >= 1 && length <= maxLength;
  }
}
