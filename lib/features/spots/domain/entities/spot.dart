import 'package:equatable/equatable.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';

/// Uno spot. L'autore non compare mai: gli spot sono anonimi.
class Spot extends Equatable {
  const Spot({
    required this.id,
    required this.channelId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.stats = const SpotStats(),
  });

  final String id;
  final String channelId;
  final String title;
  final String content;
  final DateTime createdAt;
  final SpotStats stats;

  @override
  List<Object?> get props => [id, channelId, title, content, createdAt, stats];
}
