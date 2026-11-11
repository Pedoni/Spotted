import 'package:equatable/equatable.dart';

/// L'autore di uno spot, come lo vede il proprietario del canale. Chiunque
/// altro non lo vede mai: gli spot sono anonimi.
class SpotAuthor extends Equatable {
  const SpotAuthor({required this.id, required this.username});

  final String id;
  final String username;

  @override
  List<Object?> get props => [id, username];
}
