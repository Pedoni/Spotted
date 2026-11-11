import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/chat/domain/entities/chat_message.dart';

part 'chat_message_dto.g.dart';

/// Riga degli RPC `chat_messages` e `send_message`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageDtoFromJson(json);

  final String id;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  ChatMessage toEntity() => ChatMessage(
    id: id,
    content: content,
    createdAt: createdAt,
    isMine: isMine,
  );
}
