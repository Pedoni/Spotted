import 'package:equatable/equatable.dart';

class Channel extends Equatable {
  const Channel({
    required this.id,
    required this.name,
    required this.slug,
    required this.createdAt,
    this.description,
    this.place,
    this.municipalityId,
    this.provinceCode,
    this.regionName,
    this.topicId,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;

  /// Il luogo da mostrare ("Pisa (PI)"); lo calcola il database dal comune.
  final String? place;

  /// Il comune del canale (codice ISTAT), se ne ha uno: è facoltativo.
  final String? municipalityId;
  final String? provinceCode;
  final String? regionName;
  final String? topicId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    description,
    place,
    municipalityId,
    provinceCode,
    regionName,
    topicId,
    createdAt,
  ];
}
