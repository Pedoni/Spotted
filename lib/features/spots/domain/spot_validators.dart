abstract final class SpotValidators {
  static const maxTitleLength = 100;
  static const maxContentLength = 2000;

  /// Sotto questa lunghezza non si cerca: una lettera sola trova quasi tutto.
  static const minSearchLength = 2;

  static bool isValidTitle(String value) {
    final length = value.trim().length;
    return length >= 1 && length <= maxTitleLength;
  }

  static bool isValidContent(String value) {
    final length = value.trim().length;
    return length >= 1 && length <= maxContentLength;
  }

  /// Il testo da cercare, pulito (senza spazi ai bordi), oppure `null` se non
  /// c'è una ricerca. Un testo troppo corto non è una ricerca valida.
  static String? searchText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool isSearchLongEnough(String value) =>
      value.trim().length >= minSearchLength;
}
