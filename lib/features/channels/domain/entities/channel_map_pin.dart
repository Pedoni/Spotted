import 'package:equatable/equatable.dart';

/// Un canale che sta da solo in un comune: il pin mostra la sua foto e un
/// tocco lo apre.
class MapChannel extends Equatable {
  const MapChannel({
    required this.id,
    required this.name,
    required this.slug,
    this.avatarPath,
  });

  final String id;
  final String name;
  final String slug;
  final String? avatarPath;

  @override
  List<Object?> get props => [id, name, slug, avatarPath];
}

/// Un pin della mappa dei canali: un comune che ha almeno un canale. Mai
/// l'identità di chi gestisce i canali.
class ChannelMapPin extends Equatable {
  const ChannelMapPin({
    required this.municipalityId,
    required this.municipalityLabel,
    required this.latitude,
    required this.longitude,
    required this.channelCount,
    this.channel,
  });

  /// Il codice ISTAT del comune.
  final String municipalityId;

  /// Il comune da mostrare ("Pisa (PI)").
  final String municipalityLabel;
  final double latitude;
  final double longitude;

  /// Quanti canali ci sono nel comune (con i filtri attivi).
  final int channelCount;

  /// Il canale, se è uno solo; `null` se sono di più.
  final MapChannel? channel;

  @override
  List<Object?> get props => [
    municipalityId,
    municipalityLabel,
    latitude,
    longitude,
    channelCount,
    channel,
  ];
}
