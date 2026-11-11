import 'package:equatable/equatable.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';

/// Uno spot. L'autore non compare mai: gli spot sono anonimi.
class Spot extends Equatable {
  const Spot({
    required this.id,
    required this.channelId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.stats = const SpotStats(),
    this.status = SpotStatus.published,
  });

  final String id;
  final String channelId;
  final String title;
  final String content;
  final DateTime createdAt;
  final SpotStats stats;

  /// `hidden`: nascosto dal proprietario del canale (lo vedono solo lui e
  /// l'autore).
  final SpotStatus status;

  @override
  List<Object?> get props => [
    id,
    channelId,
    title,
    content,
    createdAt,
    stats,
    status,
  ];
}
