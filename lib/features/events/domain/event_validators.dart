/// Le regole di un evento (le stesse del database).
abstract final class EventValidators {
  static const maxTitleLength = 100;
  static const maxDescriptionLength = 2000;
  static const maxLocationLength = 100;

  static bool isValidTitle(String value) {
    final length = value.trim().length;
    return length >= 1 && length <= maxTitleLength;
  }

  static bool isValidDescription(String value) {
    final length = value.trim().length;
    return length >= 1 && length <= maxDescriptionLength;
  }

  /// Il luogo è facoltativo: vuoto va bene.
  static bool isValidLocation(String value) =>
      value.trim().length <= maxLocationLength;

  /// La fine, se c'è, non può essere prima dell'inizio.
  static bool areValidDates(DateTime startsAt, DateTime? endsAt) =>
      endsAt == null || !endsAt.isBefore(startsAt);
}
