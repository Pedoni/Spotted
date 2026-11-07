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
    // 23505 = unique_violation
    if (e.code == '23505') throw ConflictFailure(e.message);
    throw UnknownFailure(e.message);
  } on SocketException {
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
