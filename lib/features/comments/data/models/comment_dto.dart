import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/comments/domain/entities/comment.dart';

part 'comment_dto.g.dart';

/// Riga degli RPC `spot_comments` e `add_comment`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class CommentDto {
  const CommentDto({
    required this.id,
    required this.spotId,
    required this.content,
    required this.createdAt,
    required this.isSpotAuthor,
    required this.isMine,
    required this.likeCount,
    required this.likedByMe,
    this.authorUsername,
  });

  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);

  final String id;
  final String spotId;
  final String content;
  final DateTime createdAt;
  final String? authorUsername;
  final bool isSpotAuthor;
  final bool isMine;
  final int likeCount;
  final bool likedByMe;

  Comment toEntity() => Comment(
    id: id,
    spotId: spotId,
    content: content,
    createdAt: createdAt,
    authorUsername: authorUsername,
    isSpotAuthor: isSpotAuthor,
    isMine: isMine,
    likeCount: likeCount,
    likedByMe: likedByMe,
  );
}
