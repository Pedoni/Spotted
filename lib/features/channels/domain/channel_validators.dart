abstract final class ChannelValidators {
  static const minNameLength = 3;
  static const maxNameLength = 60;
  static const maxDescriptionLength = 500;
  static const maxPlaceLength = 100;

  static bool isValidName(String value) {
    final length = value.trim().length;
    return length >= minNameLength && length <= maxNameLength;
  }

  static bool isValidDescription(String value) =>
      value.trim().length <= maxDescriptionLength;

  static bool isValidPlace(String value) =>
      value.trim().length <= maxPlaceLength;
}
