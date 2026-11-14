import 'package:equatable/equatable.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';

/// Uno spot con il canale in cui è pubblicato (i miei spot, la Home).
class SpotWithChannel extends Equatable {
  const SpotWithChannel({
    required this.spot,
    required this.channelName,
    required this.channelSlug,
  });

  final Spot spot;
  final String channelName;
  final String channelSlug;

  @override
  List<Object?> get props => [spot, channelName, channelSlug];
}
