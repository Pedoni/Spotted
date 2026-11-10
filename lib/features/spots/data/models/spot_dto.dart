import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';

part 'spot_dto.g.dart';

/// Colonne di `spots` leggibili dai client. `author_id` è escluso di
/// proposito: gli spot sono anonimi.
const spotColumns = 'id, channel_id, title, content, created_at';

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SpotDto {
  const SpotDto({
    required this.id,
    required this.channelId,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory SpotDto.fromJson(Map<String, dynamic> json) =>
      _$SpotDtoFromJson(json);

  final String id;
  final String channelId;
  final String title;
  final String content;
  final DateTime createdAt;

  Spot toEntity() => Spot(
    id: id,
    channelId: channelId,
    title: title,
    content: content,
    createdAt: createdAt,
  );
}
