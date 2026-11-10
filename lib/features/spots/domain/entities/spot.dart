import 'package:equatable/equatable.dart';

/// Uno spot. L'autore non compare mai: gli spot sono anonimi.
class Spot extends Equatable {
  const Spot({
    required this.id,
    required this.channelId,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String channelId;
  final String title;
  final String content;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, channelId, title, content, createdAt];
}
