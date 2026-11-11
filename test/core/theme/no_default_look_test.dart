import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Impedisce di reintrodurre l'aspetto di default di Material: colori, font e
/// widget "di base" devono passare dal tema (`lib/core/theme`) e dai widget
/// condivisi.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .where((f) => !f.path.contains('lib/l10n/'))
      .where((f) => !f.path.contains('lib/core/theme/'))
      .toList();

  /// Le righe di [pattern] fuori dal tema, come "file:riga".
  List<String> find(Pattern pattern, {Pattern? except}) {
    final found = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (line.contains(pattern) &&
            (except == null || !line.contains(except))) {
          found.add('${file.path}:${i + 1}');
        }
      }
    }
    return found;
  }

  test(
    'nessun FilledButton.tonal: avrebbe il colore secondario di default',
    () {
      expect(find('FilledButton.tonal'), isEmpty);
    },
  );

  test('nessun CircleAvatar: gli avatar sono ChannelAvatar e UserAvatar', () {
    expect(find('CircleAvatar'), isEmpty);
  });

  test('nessun colore scritto a mano: si usa il ColorScheme', () {
    expect(find(RegExp(r'Colors\.(?!transparent)')), isEmpty);
    expect(find(RegExp(r'\bColor\(0x')), isEmpty);
  });

  test('nessun font scritto a mano: si usa il tema o AppFonts', () {
    expect(find(RegExp(r"fontFamily:\s*'")), isEmpty);
  });

  test('i controlli sono stati trovati', () {
    // Se la cartella cambiasse e il test non vedesse più i file, passerebbe a
    // vuoto.
    expect(files.length, greaterThan(100));
  });
}
