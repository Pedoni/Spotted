import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';

class RevealIdentity {
  const RevealIdentity(this._repository);

  final ChatRepository _repository;

  Future<void> call(String chatId) => _repository.revealIdentity(chatId);
}
