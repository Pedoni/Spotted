import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/core/supabase/timeout_client.dart';

void main() {
  http.Client slowInner() {
    return MockClient((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return http.Response('ok', 200);
    });
  }

  test('lancia TimeoutException se il server non risponde in tempo', () {
    final client = TimeoutClient(
      inner: slowInner(),
      timeout: const Duration(milliseconds: 20),
    );

    expect(
      client.get(Uri.parse('https://example.com')),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('con guardFailures diventa NetworkFailure', () {
    final client = TimeoutClient(
      inner: slowInner(),
      timeout: const Duration(milliseconds: 20),
    );

    expect(
      guardFailures(() => client.get(Uri.parse('https://example.com'))),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('una risposta in tempo passa invariata', () async {
    final client = TimeoutClient(
      inner: slowInner(),
      timeout: const Duration(seconds: 2),
    );

    final response = await client.get(Uri.parse('https://example.com'));

    expect(response.statusCode, 200);
    expect(response.body, 'ok');
  });
}
