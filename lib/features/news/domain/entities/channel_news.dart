import 'package:equatable/equatable.dart';

/// Una news di un canale: una comunicazione del canale, scritta dal suo
/// proprietario. Non porta mai l'autore: parla il canale.
class ChannelNews extends Equatable {
  const ChannelNews({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelSlug,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String channelId;
  final String channelName;
  final String channelSlug;
  final String title;
  final String body;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    channelId,
    channelName,
    channelSlug,
    title,
    body,
    createdAt,
  ];
}
