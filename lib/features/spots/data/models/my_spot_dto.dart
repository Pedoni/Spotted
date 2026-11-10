import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/spots/domain/entities/my_spot.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';

part 'my_spot_dto.g.dart';

/// Riga dell'RPC `my_spots_page`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class MySpotDto {
  const MySpotDto({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelSlug,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory MySpotDto.fromJson(Map<String, dynamic> json) =>
      _$MySpotDtoFromJson(json);

  final String id;
  final String channelId;
  final String channelName;
  final String channelSlug;
  final String title;
  final String content;
  final DateTime createdAt;

  MySpot toEntity() => MySpot(
    spot: Spot(
      id: id,
      channelId: channelId,
      title: title,
      content: content,
      createdAt: createdAt,
    ),
    channelName: channelName,
    channelSlug: channelSlug,
  );
}
