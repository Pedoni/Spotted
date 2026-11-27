/// Un numero in forma breve, per gli spazi stretti: fino a 999 è il numero, da
/// 1000 si va a scaglioni di un decimale con la K ("1K", "1.1K", ...,
/// "999.9K"), da un milione con la M ("1M", "1.1M", ...). Il decimale si
/// tronca, non si arrotonda: 1999 è "1.9K", mai "2K" (e 999999 non diventa
/// "1000K"); lo ".0" non si scrive.
String formatCompactCount(int value) {
  if (value < 1000) return '${value < 0 ? 0 : value}';
  if (value < 1000000) return _scaled(value, 1000, 'K');
  return _scaled(value, 1000000, 'M');
}

String _scaled(int value, int unit, String suffix) {
  final whole = value ~/ unit;
  final tenth = (value ~/ (unit ~/ 10)) % 10;
  return tenth == 0 ? '$whole$suffix' : '$whole.$tenth$suffix';
}
