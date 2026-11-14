import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';
import 'package:spotted/features/spots/domain/entities/spot_with_channel.dart';

part 'spot_with_channel_dto.g.dart';

/// Riga degli RPC `my_spots_page` e `followed_spots_page`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SpotWithChannelDto {
  const SpotWithChannelDto({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelSlug,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    this.status = SpotStatus.published,
  });

  factory SpotWithChannelDto.fromJson(Map<String, dynamic> json) =>
      _$SpotWithChannelDtoFromJson(json);

  final String id;
  final String channelId;
  final String channelName;
  final String channelSlug;
  final String title;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  @JsonKey(
    defaultValue: SpotStatus.published,
    unknownEnumValue: SpotStatus.published,
  )
  final SpotStatus status;

  SpotWithChannel toEntity() => SpotWithChannel(
    spot: Spot(
      id: id,
      channelId: channelId,
      title: title,
      content: content,
      createdAt: createdAt,
      stats: SpotStats(
        likeCount: likeCount,
        commentCount: commentCount,
        likedByMe: likedByMe,
      ),
      status: status,
    ),
    channelName: channelName,
    channelSlug: channelSlug,
  );
}
