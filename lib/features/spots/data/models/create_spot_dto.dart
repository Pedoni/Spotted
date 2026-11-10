import 'package:json_annotation/json_annotation.dart';

part 'create_spot_dto.g.dart';

/// Corpo dell'insert su `spots`. Sono le sole colonne scrivibili dai client;
/// `status` e le date le decide il database.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class CreateSpotDto {
  const CreateSpotDto({
    required this.authorId,
    required this.channelId,
    required this.title,
    required this.content,
  });

  final String authorId;
  final String channelId;
  final String title;
  final String content;

  Map<String, dynamic> toJson() => _$CreateSpotDtoToJson(this);
}
