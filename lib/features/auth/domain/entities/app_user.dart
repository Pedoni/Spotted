import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({required this.id, required this.email, this.pendingEmail});

  final String id;
  final String email;

  /// Il nuovo indirizzo che l'utente ha chiesto e non ha ancora confermato
  /// (finché non lo fa, l'indirizzo valido resta [email]).
  final String? pendingEmail;

  @override
  List<Object?> get props => [id, email, pendingEmail];
}
