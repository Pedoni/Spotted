import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/chat/domain/entities/chat_kind.dart';
import 'package:spotted/features/chat/domain/entities/chat_message_kind.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';

part 'chat_summary_dto.g.dart';

/// Riga degli RPC `my_chats_page` e `chat_detail`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class ChatSummaryDto {
  const ChatSummaryDto({
    required this.id,
    required this.channelName,
    required this.channelSlug,
    required this.iAmAuthor,
    required this.identityRevealed,
    required this.createdAt,
    this.spotId,
    this.spotTitle,
    this.kind = ChatKind.spot,
    this.lastMessageKind,
    this.unread = false,
    this.otherUsername,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageIsMine,
  });

  factory ChatSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ChatSummaryDtoFromJson(json);

  final String id;
  final String? spotId;
  final String? spotTitle;
  final String channelName;
  final String channelSlug;
  final bool iAmAuthor;
  final String? otherUsername;
  final bool identityRevealed;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool? lastMessageIsMine;

  /// Assente nelle risposte di prima: erano tutte chat degli spot.
  @JsonKey(defaultValue: ChatKind.spot, unknownEnumValue: ChatKind.spot)
  final ChatKind kind;
  @JsonKey(unknownEnumValue: ChatMessageKind.text)
  final ChatMessageKind? lastMessageKind;

  @JsonKey(defaultValue: false)
  final bool unread;

  ChatSummary toEntity() => ChatSummary(
    id: id,
    spotId: spotId,
    spotTitle: spotTitle,
    channelName: channelName,
    channelSlug: channelSlug,
    iAmAuthor: iAmAuthor,
    otherUsername: otherUsername,
    identityRevealed: identityRevealed,
    createdAt: createdAt,
    lastMessage: lastMessage,
    lastMessageAt: lastMessageAt,
    lastMessageIsMine: lastMessageIsMine,
    kind: kind,
    lastMessageKind: lastMessageKind,
    unread: unread,
  );
}
