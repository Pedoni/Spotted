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

  /// Le righe di [pattern] fuori dal tema, come "file:riga". I file in
  /// [exceptFiles] sono quelli in cui è lecito.
  List<String> find(
    Pattern pattern, {
    Pattern? except,
    List<String> exceptFiles = const [],
  }) {
    final found = <String>[];
    for (final file in files) {
      if (exceptFiles.any(file.path.endsWith)) continue;
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

  test('nessuno spinner: i caricamenti sono scheletri', () {
    // L'unico spinner è quello piccolo dentro i pulsanti.
    expect(
      find(
        'CircularProgressIndicator',
        exceptFiles: ['lib/core/widgets/inline_progress.dart'],
      ),
      isEmpty,
    );
    expect(find('LinearProgressIndicator'), isEmpty);
  });

  test(
    'Skeletonizer si usa solo tramite Skeleton, che ha tema e accessibilità',
    () {
      expect(
        find(
          RegExp(r'\bSkeletonizer(\(|\.)'),
          exceptFiles: ['lib/core/widgets/skeleton.dart'],
        ),
        isEmpty,
      );
    },
  );

  test('i controlli sono stati trovati', () {
    // Se la cartella cambiasse e il test non vedesse più i file, passerebbe a
    // vuoto.
    expect(files.length, greaterThan(100));
  });
}
