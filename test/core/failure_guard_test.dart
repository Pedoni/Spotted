import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/error/failure_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('unique_violation diventa ConflictFailure', () {
    expect(
      guardFailures<void>(
        () => throw const PostgrestException(message: 'dup', code: '23505'),
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('altri errori Postgrest diventano UnknownFailure', () {
    expect(
      guardFailures<void>(
        () => throw const PostgrestException(message: 'boom', code: '42501'),
      ),
      throwsA(isA<UnknownFailure>()),
    );
  });

  test('errori di rete diventano NetworkFailure', () {
    expect(
      guardFailures<void>(() => throw const SocketException('offline')),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('i Failure passano invariati', () {
    expect(
      guardFailures<void>(() => throw const NotFoundFailure()),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('il risultato passa invariato', () async {
    expect(await guardFailures(() async => 42), 42);
  });
}
