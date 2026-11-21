import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';

class MarkChatRead {
  const MarkChatRead(this._repository);

  final ChatRepository _repository;

  Future<void> call(String chatId) => _repository.markChatRead(chatId);
}
