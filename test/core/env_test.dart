import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/config/env.dart';

void main() {
  test('Env is not configured without --dart-define', () {
    expect(Env.isConfigured, isFalse);
  });
}
