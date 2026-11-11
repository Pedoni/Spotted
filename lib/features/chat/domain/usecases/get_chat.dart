import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';

class GetChat {
  const GetChat(this._repository);

  final ChatRepository _repository;

  Future<ChatSummary> call(String chatId) => _repository.getChat(chatId);
}
