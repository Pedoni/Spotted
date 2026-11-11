import 'package:spotted/features/chat/domain/entities/chat_message.dart';
import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';

class GetChatMessages {
  const GetChatMessages(this._repository);

  final ChatRepository _repository;

  Future<List<ChatMessage>> call({
    required String chatId,
    required int offset,
    required int limit,
  }) => _repository.getMessages(chatId: chatId, offset: offset, limit: limit);
}
