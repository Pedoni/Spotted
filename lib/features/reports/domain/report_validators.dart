abstract final class ReportValidators {
  static const maxDetailsLength = 500;

  /// I dettagli sono facoltativi: vuoti vanno bene.
  static bool isDetailsValid(String? value) {
    return (value?.trim().length ?? 0) <= maxDetailsLength;
  }
}
