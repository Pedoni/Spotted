import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';

part 'news_dto.g.dart';

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class NewsDto {
  const NewsDto({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelSlug,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory NewsDto.fromJson(Map<String, dynamic> json) =>
      _$NewsDtoFromJson(json);

  final String id;
  final String channelId;
  final String channelName;
  final String channelSlug;
  final String title;
  final String body;
  final DateTime createdAt;

  ChannelNews toEntity() => ChannelNews(
    id: id,
    channelId: channelId,
    channelName: channelName,
    channelSlug: channelSlug,
    title: title,
    body: body,
    createdAt: createdAt,
  );
}
