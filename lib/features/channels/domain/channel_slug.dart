import 'dart:math';

/// Genera lo slug (parte dell'URL) di un canale a partire dal nome.
abstract final class ChannelSlug {
  static const maxLength = 50;
  static const _fallback = 'canale';
  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  static const _accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
    'ß': 'ss',
  };

  /// "Spotted Università di Pisa!" -> "spotted-universita-di-pisa".
  static String slugify(String name) {
    final buffer = StringBuffer();
    for (final rune in name.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    var slug = buffer
        .toString()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.length > maxLength) {
      slug = slug.substring(0, maxLength).replaceAll(RegExp(r'-+$'), '');
    }
    return slug.isEmpty ? _fallback : slug;
  }

  /// Suffisso casuale di 4 caratteri per risolvere le collisioni.
  static String randomSuffix([Random? random]) {
    final rng = random ?? Random();
    return List.generate(
      4,
      (_) => _alphabet[rng.nextInt(_alphabet.length)],
    ).join();
  }
}
