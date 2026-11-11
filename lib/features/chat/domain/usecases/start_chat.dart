import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';

class StartChat {
  const StartChat(this._repository);

  final ChatRepository _repository;

  Future<String> call(String commentId) => _repository.startChat(commentId);
}
