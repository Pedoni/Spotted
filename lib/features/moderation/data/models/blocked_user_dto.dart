import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/moderation/domain/entities/blocked_user.dart';

part 'blocked_user_dto.g.dart';

/// Riga dell'RPC `channel_blocked_users`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class BlockedUserDto {
  const BlockedUserDto({
    required this.id,
    required this.username,
    required this.createdAt,
  });

  factory BlockedUserDto.fromJson(Map<String, dynamic> json) =>
      _$BlockedUserDtoFromJson(json);

  final String id;
  final String username;
  final DateTime createdAt;

  BlockedUser toEntity() =>
      BlockedUser(id: id, username: username, createdAt: createdAt);
}
