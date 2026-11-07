import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
  });

  final String id;
  final String username;
  final String? firstName;
  final String? lastName;

  /// "Nome Cognome", oppure null se mancano entrambi.
  String? get fullName {
    final parts = [
      firstName,
      lastName,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  @override
  List<Object?> get props => [id, username, firstName, lastName];
}
