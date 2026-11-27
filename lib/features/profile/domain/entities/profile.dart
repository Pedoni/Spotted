import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.birthDate,
  });

  final String id;
  final String username;
  final String? firstName;
  final String? lastName;

  /// La data di nascita (solo il giorno), se l'utente l'ha indicata.
  final DateTime? birthDate;

  /// "Nome Cognome", oppure null se mancano entrambi.
  String? get fullName {
    final parts = [
      firstName,
      lastName,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  @override
  List<Object?> get props => [id, username, firstName, lastName, birthDate];
}
