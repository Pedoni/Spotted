import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/moderation/domain/entities/spot_author.dart';

part 'spot_author_dto.g.dart';

/// Riga dell'RPC `channel_spot_author`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SpotAuthorDto {
  const SpotAuthorDto({required this.authorId, required this.username});

  factory SpotAuthorDto.fromJson(Map<String, dynamic> json) =>
      _$SpotAuthorDtoFromJson(json);

  final String authorId;
  final String username;

  SpotAuthor toEntity() => SpotAuthor(id: authorId, username: username);
}
