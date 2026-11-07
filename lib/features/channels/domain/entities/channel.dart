import 'package:equatable/equatable.dart';

class Channel extends Equatable {
  const Channel({
    required this.id,
    required this.name,
    required this.slug,
    required this.createdAt,
    this.description,
    this.place,
    this.topicId,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? place;
  final String? topicId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    description,
    place,
    topicId,
    createdAt,
  ];
}
