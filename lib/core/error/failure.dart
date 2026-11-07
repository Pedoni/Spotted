import 'package:equatable/equatable.dart';

/// Errore di dominio. I repository lanciano un [Failure]; `AsyncValue` lo
/// trasporta fino alla UI.
sealed class Failure extends Equatable implements Exception {
  const Failure([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

enum AuthFailureReason {
  invalidCredentials,
  emailTaken,
  usernameTaken,
  invalidInput,
  weakPassword,
  unknown,
}

final class AuthFailure extends Failure {
  const AuthFailure(this.reason, [super.message]);

  final AuthFailureReason reason;

  @override
  List<Object?> get props => [reason, message];
}

/// Violazione di un vincolo di unicità (es. slug già usato).
final class ConflictFailure extends Failure {
  const ConflictFailure([super.message]);
}

/// Dati non validi (controllo lato dominio).
final class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message]);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message]);
}
