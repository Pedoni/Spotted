import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/chat/domain/entities/chat_message.dart';
import 'package:spotted/features/chat/domain/message_validators.dart';
import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';

class SendMessage {
  const SendMessage(this._repository);

  final ChatRepository _repository;

  /// Valida il testo (togliendo gli spazi ai bordi) e lo invia.
  Future<ChatMessage> call({
    required String chatId,
    required String content,
  }) async {
    if (!MessageValidators.isValid(content)) throw const ValidationFailure();
    return _repository.sendMessage(chatId: chatId, content: content.trim());
  }
}
