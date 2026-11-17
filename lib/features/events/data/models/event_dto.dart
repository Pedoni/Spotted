import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';

part 'event_dto.g.dart';

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class EventDto {
  const EventDto({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelSlug,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.createdAt,
    this.location,
    this.endsAt,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  final String id;
  final String channelId;
  final String channelName;
  final String channelSlug;
  final String title;
  final String description;
  final String? location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;

  ChannelEvent toEntity() => ChannelEvent(
    id: id,
    channelId: channelId,
    channelName: channelName,
    channelSlug: channelSlug,
    title: title,
    description: description,
    location: location,
    startsAt: startsAt,
    endsAt: endsAt,
    createdAt: createdAt,
  );
}
