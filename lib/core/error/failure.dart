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

final class AuthFailure extends Failure {
  const AuthFailure([super.message]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message]);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message]);
}
