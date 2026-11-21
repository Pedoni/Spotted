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

enum ImageFailureReason {
  /// L'immagine pesa troppo.
  tooLarge,

  /// Il file non è un'immagine che si può usare.
  invalid,
}

/// Un'immagine scelta dall'utente che non si può usare.
final class ImageFailure extends Failure {
  const ImageFailure(this.reason, [super.message]);

  final ImageFailureReason reason;

  @override
  List<Object?> get props => [reason, message];
}

enum LimitReason {
  /// Troppi messaggi all'utente senza risposta del canale.
  unansweredMessages,

  /// Troppi spot in attesa nello stesso canale.
  pendingSpots,
}

/// L'utente ha raggiunto un limite (messaggi senza risposta, spot in attesa).
final class LimitFailure extends Failure {
  const LimitFailure(this.reason, [super.message]);

  final LimitReason reason;

  @override
  List<Object?> get props => [reason, message];
}

/// Operazione non consentita (es. violazione RLS).
final class PermissionFailure extends Failure {
  const PermissionFailure([super.message]);
}

/// Il token di accesso non è più valido.
final class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.message]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message]);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message]);
}
