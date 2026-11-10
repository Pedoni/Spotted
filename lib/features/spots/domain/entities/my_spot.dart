import 'package:equatable/equatable.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';

/// Uno spot scritto dall'utente loggato, con il canale in cui è pubblicato.
class MySpot extends Equatable {
  const MySpot({
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
