import 'dart:async';
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

  test('check_violation (23514) diventa ValidationFailure', () {
    expect(
      guardFailures<void>(
        () => throw const PostgrestException(message: 'check', code: '23514'),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('altri errori Postgrest diventano UnknownFailure', () {
    expect(
      guardFailures<void>(
        () => throw const PostgrestException(message: 'boom', code: 'XX000'),
      ),
      throwsA(isA<UnknownFailure>()),
    );
  });

  test('permesso negato (42501) diventa PermissionFailure', () {
    expect(
      guardFailures<void>(
        () => throw const PostgrestException(message: 'denied', code: '42501'),
      ),
      throwsA(isA<PermissionFailure>()),
    );
  });

  test('JWT scaduto diventa SessionExpiredFailure', () {
    expect(
      guardFailures<void>(
        () => throw const PostgrestException(
          message: 'JWT expired',
          code: 'PGRST301',
        ),
      ),
      throwsA(isA<SessionExpiredFailure>()),
    );
    expect(
      guardFailures<void>(
        () => throw const PostgrestException(message: 'invalid JWT'),
      ),
      throwsA(isA<SessionExpiredFailure>()),
    );
  });

  test('timeout diventa NetworkFailure', () {
    expect(
      guardFailures<void>(() => throw TimeoutException('lento')),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('errori di rete diventano NetworkFailure', () {
    expect(
      guardFailures<void>(() => throw const SocketException('offline')),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('risposte con tipi inattesi (TypeError) diventano UnknownFailure', () {
    expect(
      guardFailures<String>(() async {
        final json = <String, dynamic>{'name': 42};
        return json['name'] as String;
      }),
      throwsA(isA<UnknownFailure>()),
    );
  });

  test('FormatException diventa UnknownFailure', () {
    expect(
      guardFailures<DateTime>(() async => DateTime.parse('non-una-data')),
      throwsA(isA<UnknownFailure>()),
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
