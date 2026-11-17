import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/format/count_format.dart';

void main() {
  group('formatCompactCount', () {
    test('fino a 999 è il numero', () {
      expect(formatCompactCount(0), '0');
      expect(formatCompactCount(1), '1');
      expect(formatCompactCount(42), '42');
      expect(formatCompactCount(999), '999');
    });

    test('da 1000 va a scaglioni con la K', () {
      expect(formatCompactCount(1000), '1K');
      expect(formatCompactCount(1099), '1K');
      expect(formatCompactCount(1100), '1.1K');
      expect(formatCompactCount(1500), '1.5K');
      expect(formatCompactCount(9900), '9.9K');
      expect(formatCompactCount(10000), '10K');
      expect(formatCompactCount(12345), '12.3K');
      expect(formatCompactCount(100000), '100K');
    });

    test('il decimale si tronca, non si arrotonda', () {
      expect(formatCompactCount(1999), '1.9K');
      expect(formatCompactCount(1950), '1.9K');
      expect(formatCompactCount(999949), '999.9K');
    });

    test('l ultimo valore con la K non diventa 1000K', () {
      expect(formatCompactCount(999999), '999.9K');
      expect(formatCompactCount(999999), isNot('1000K'));
    });

    test('da un milione va a scaglioni con la M', () {
      expect(formatCompactCount(1000000), '1M');
      expect(formatCompactCount(1099999), '1M');
      expect(formatCompactCount(1100000), '1.1M');
      expect(formatCompactCount(12345678), '12.3M');
      expect(formatCompactCount(250000000), '250M');
    });

    test('un numero negativo vale zero', () {
      expect(formatCompactCount(-5), '0');
    });
  });
}
