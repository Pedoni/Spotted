import 'package:equatable/equatable.dart';

/// Un evento di un canale: qualcosa che succede in una data, scritto dal
/// proprietario del canale. Non porta mai l'autore: parla il canale.
class ChannelEvent extends Equatable {
  const ChannelEvent({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelSlug,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.createdAt,
    this.location,
    this.endsAt,
  });

  final String id;
  final String channelId;
  final String channelName;
  final String channelSlug;
  final String title;
  final String description;

  /// Testo libero (per esempio "Aula magna"): il comune è quello del canale.
  final String? location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    channelId,
    channelName,
    channelSlug,
    title,
    description,
    location,
    startsAt,
    endsAt,
    createdAt,
  ];
}
