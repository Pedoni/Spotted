import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/licenses/font_licenses.dart';

import '../../helpers/fake_asset_bundle.dart';

Future<List<LicenseEntry>> registeredEntries() =>
    LicenseRegistry.licenses.toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Il registro è uno solo per tutta l'app: lo si svuota a ogni prova (e con
  // lui le licenze che Flutter aggiunge da solo, che qui non servono).
  setUp(LicenseRegistry.reset);
  tearDown(LicenseRegistry.reset);

  group('registrazione', () {
    test('aggiunge una licenza per ogni font, con il suo testo', () async {
      registerFontLicenses(
        FakeAssetBundle({
          for (final font in fontLicenses)
            font.asset: 'Testo della licenza di ${font.name}',
        }),
      );

      final entries = await registeredEntries();

      expect(entries, hasLength(fontLicenses.length));
      expect(
        entries.expand((entry) => entry.packages),
        containsAll(['Bricolage Grotesque (font)', 'Plus Jakarta Sans (font)']),
      );
      final texts = entries
          .map((e) => e.paragraphs.map((p) => p.text).join(' '))
          .join('\n');
      expect(texts, contains('Testo della licenza di Bricolage Grotesque'));
      expect(texts, contains('Testo della licenza di Plus Jakarta Sans'));
    });

    test('ogni licenza è collegata solo al suo font', () async {
      registerFontLicenses(
        FakeAssetBundle({for (final font in fontLicenses) font.asset: 'testo'}),
      );

      final entries = await registeredEntries();

      for (final entry in entries) {
        expect(entry.packages, hasLength(1));
      }
    });

    test('un file che manca non fa sparire le altre licenze', () async {
      registerFontLicenses(
        FakeAssetBundle({fontLicenses.last.asset: 'Solo questa licenza'}),
      );

      final entries = await registeredEntries();

      expect(entries, hasLength(1));
      expect(entries.single.packages.single, 'Plus Jakarta Sans (font)');
    });

    test('senza nessun file non ci sono licenze e non dà errori', () async {
      registerFontLicenses(FakeAssetBundle({}));

      expect(await registeredEntries(), isEmpty);
    });

    test('i paragrafi seguono le righe del testo', () async {
      registerFontLicenses(
        FakeAssetBundle({
          for (final font in fontLicenses) font.asset: 'Prima\n\nSeconda',
        }),
      );

      final entries = await registeredEntries();

      expect(entries.first.paragraphs.map((p) => p.text), contains('Prima'));
      expect(entries.first.paragraphs.map((p) => p.text), contains('Seconda'));
    });
  });

  group('file veri', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    test('i testi esistono e sono quelli della licenza OFL', () {
      for (final font in fontLicenses) {
        final file = File(font.asset);
        expect(file.existsSync(), isTrue, reason: font.asset);
        expect(
          file.readAsStringSync(),
          contains('SIL OPEN FONT LICENSE'),
          reason: font.asset,
        );
      }
    });

    test('sono dichiarati in pubspec.yaml, altrimenti l app non li legge', () {
      for (final font in fontLicenses) {
        expect(pubspec, contains('- ${font.asset}'), reason: font.asset);
      }
    });

    test('si leggono davvero come risorse dell app', () async {
      for (final font in fontLicenses) {
        final text = await rootBundle.loadString(font.asset);
        expect(text, contains('Copyright'), reason: font.asset);
      }
    });

    test('ci sono i due font dell app', () {
      expect(fontLicenses.map((f) => f.name), [
        'Bricolage Grotesque',
        'Plus Jakarta Sans',
      ]);
    });
  });
}
