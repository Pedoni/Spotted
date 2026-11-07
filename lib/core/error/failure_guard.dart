import 'dart:async';
import 'dart:io';

import 'package:spotted/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Esegue [action] traducendo le eccezioni di Supabase e di rete in [Failure].
Future<T> guardFailures<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on Failure {
    rethrow;
  } on AuthRetryableFetchException {
    throw const NetworkFailure();
  } on PostgrestException catch (e) {
    throw _fromPostgrest(e);
  } on SocketException {
    throw const NetworkFailure();
  } on TimeoutException {
    throw const NetworkFailure();
    // ignore: avoid_catching_errors, un JSON inatteso lancia proprio TypeError
  } on TypeError catch (e) {
    // Una risposta con tipi inattesi (es. campo null o di tipo diverso) fa
    // lanciare un TypeError, che non è un'Exception.
    throw UnknownFailure('Unexpected data format: $e');
  } on Exception catch (e) {
    throw UnknownFailure(e.toString());
  }
}

Failure _fromPostgrest(PostgrestException e) {
  final code = e.code;
  final message = e.message;
  return switch (code) {
    // unique_violation
    '23505' => ConflictFailure(message),
    // insufficient_privilege (anche violazioni di RLS)
    '42501' => PermissionFailure(message),
    // PostgREST: JWT scaduto o non valido
    'PGRST301' || 'PGRST303' => SessionExpiredFailure(message),
    _ when message.toLowerCase().contains('jwt') => SessionExpiredFailure(
      message,
    ),
    _ => UnknownFailure(message),
  };
}
