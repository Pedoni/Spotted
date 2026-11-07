import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

void main() {
  test('failures with same type and message are equal', () {
    expect(const NetworkFailure('x'), const NetworkFailure('x'));
    expect(const NetworkFailure('x'), isNot(const AuthFailure('x')));
  });
}
