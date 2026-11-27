import 'package:equatable/equatable.dart';

/// Un utente bloccato dal canale, come lo vede il proprietario. L'id è quello
/// del blocco, non dell'utente: serve solo per sbloccarlo.
class BlockedUser extends Equatable {
  const BlockedUser({
    required this.id,
    required this.username,
    required this.createdAt,
  });

  final String id;
  final String username;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, username, createdAt];
}
