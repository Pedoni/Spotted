import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';

part 'channel_dto.g.dart';

/// Colonne di `channels` leggibili dai client. `owner_id` è escluso di
/// proposito: il proprietario di un canale non è mostrato.
const channelColumns =
    'id, topic_id, name, slug, description, place, created_at';

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class ChannelDto {
  const ChannelDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.createdAt,
    this.description,
    this.place,
    this.topicId,
  });

  factory ChannelDto.fromJson(Map<String, dynamic> json) =>
      _$ChannelDtoFromJson(json);

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? place;
  final String? topicId;
  final DateTime createdAt;

  Channel toEntity() => Channel(
    id: id,
    name: name,
    slug: slug,
    description: description,
    place: place,
    topicId: topicId,
    createdAt: createdAt,
  );
}
