import 'package:flutter/material.dart';

/// Un testo con le parti uguali a [query] evidenziate (in giallo, il colore
/// dell'evidenziatore). Come la ricerca nel database, non distingue maiuscole e
/// accenti: cercando "perche" si evidenzia "Perché".
class HighlightedText extends StatelessWidget {
  const HighlightedText(this.text, {this.query, this.style, super.key});

  final String text;

  /// Il testo cercato; se è `null` o vuoto il testo resta com'è.
  final String? query;
  final TextStyle? style;

  /// Lettere con accento e la lettera semplice che le sostituisce. Una per una:
  /// la lunghezza del testo non cambia, quindi le posizioni trovate valgono
  /// anche per il testo originale.
  static const _plain = {
    'a': 'àáâãäåāăą',
    'c': 'çćĉċč',
    'e': 'èéêëēĕėęě',
    'g': 'ĝğġģ',
    'i': 'ìíîïĩīĭį',
    'l': 'ĺļľł',
    'n': 'ñńņň',
    'o': 'òóôõöøōŏő',
    's': 'śŝşš',
    'u': 'ùúûüũūŭůűų',
    'y': 'ýÿ',
    'z': 'źżž',
  };

  static final Map<String, String> _fold = {
    for (final MapEntry(:key, :value) in _plain.entries)
      for (final char in value.split('')) char: key,
  };

  /// Minuscolo e senza accenti, lettera per lettera.
  static String fold(String text) {
    return text.toLowerCase().split('').map((c) => _fold[c] ?? c).join();
  }

  /// Le parti di [text] che coincidono con [query], in ordine e senza
  /// sovrapporsi. Vuoto se non c'è niente da evidenziare.
  static List<TextRange> matches(String text, String? query) {
    final needle = fold((query ?? '').trim());
    if (needle.isEmpty) return const [];
    final haystack = fold(text);
    // Difesa: se per qualche carattere il minuscolo cambiasse la lunghezza le
    // posizioni non varrebbero più per il testo originale, e meglio non
    // evidenziare che sbagliare pezzo (o uscire dai limiti).
    if (haystack.length != text.length) return const [];

    final ranges = <TextRange>[];
    var from = 0;
    while (true) {
      final index = haystack.indexOf(needle, from);
      if (index < 0) break;
      ranges.add(TextRange(start: index, end: index + needle.length));
      from = index + needle.length;
    }
    return ranges;
  }

  @override
  Widget build(BuildContext context) {
    final ranges = matches(text, query);
    if (ranges.isEmpty) return Text(text, style: style);

    final scheme = Theme.of(context).colorScheme;
    final highlight = TextStyle(
      backgroundColor: scheme.tertiaryContainer,
      color: scheme.onTertiaryContainer,
    );

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, range.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: highlight,
        ),
      );
      cursor = range.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));

    return Text.rich(TextSpan(style: style, children: spans));
  }
}
