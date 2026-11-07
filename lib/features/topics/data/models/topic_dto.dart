import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/topics/domain/entities/topic.dart';

part 'topic_dto.g.dart';

/// Colonne di `topics` da richiedere.
const topicColumns = 'id, name, description';

@JsonSerializable(createToJson: false)
class TopicDto {
  const TopicDto({required this.id, required this.name, this.description});

  factory TopicDto.fromJson(Map<String, dynamic> json) =>
      _$TopicDtoFromJson(json);

  final String id;
  final String name;
  final String? description;

  Topic toEntity() => Topic(id: id, name: name, description: description);
}
