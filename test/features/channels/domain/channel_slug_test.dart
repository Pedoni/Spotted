import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/channels/domain/channel_slug.dart';

void main() {
  group('slugify', () {
    test('minuscolo, trattini al posto dei separatori', () {
      expect(ChannelSlug.slugify('Spotted Pisa'), 'spotted-pisa');
      expect(ChannelSlug.slugify('  a   b  '), 'a-b');
    });

    test('toglie accenti e punteggiatura', () {
      expect(
        ChannelSlug.slugify("Spotted Università d'Italia!"),
        'spotted-universita-d-italia',
      );
      expect(ChannelSlug.slugify('Caffè & Più'), 'caffe-piu');
    });

    test('nome senza caratteri validi: slug di ripiego', () {
      expect(ChannelSlug.slugify('!!!'), 'canale');
      expect(ChannelSlug.slugify('日本'), 'canale');
    });

    test('limita la lunghezza senza trattino finale', () {
      final slug = ChannelSlug.slugify('${'a' * 49} bbbbbb');
      expect(slug.length, lessThanOrEqualTo(ChannelSlug.maxLength));
      expect(slug.endsWith('-'), isFalse);
    });
  });

  test('randomSuffix: 4 caratteri alfanumerici minuscoli', () {
    final suffix = ChannelSlug.randomSuffix(Random(1));
    expect(suffix, matches(RegExp(r'^[a-z0-9]{4}$')));
  });
}
