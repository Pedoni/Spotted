import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/auth/domain/auth_validators.dart';

void main() {
  test('email', () {
    expect(AuthValidators.isValidEmail('a@b.it'), isTrue);
    expect(AuthValidators.isValidEmail(' a@b.it '), isTrue);
    expect(AuthValidators.isValidEmail('a@b'), isFalse);
    expect(AuthValidators.isValidEmail('ab.it'), isFalse);
    expect(AuthValidators.isValidEmail(''), isFalse);
  });

  test('username: 3-30 caratteri, lettere, numeri, underscore', () {
    expect(AuthValidators.isValidUsername('mario_88'), isTrue);
    expect(AuthValidators.isValidUsername('ab'), isFalse);
    expect(AuthValidators.isValidUsername('a' * 31), isFalse);
    expect(AuthValidators.isValidUsername('ma rio'), isFalse);
    expect(AuthValidators.isValidUsername('mario!'), isFalse);
  });

  test('password: minimo 8 caratteri', () {
    expect(AuthValidators.isValidPassword('1234567'), isFalse);
    expect(AuthValidators.isValidPassword('12345678'), isTrue);
  });

  test('nome: non vuoto e al massimo 50 caratteri', () {
    expect(AuthValidators.isValidName('  '), isFalse);
    expect(AuthValidators.isValidName('Mario'), isTrue);
    expect(AuthValidators.isValidName('a' * 51), isFalse);
  });
}
