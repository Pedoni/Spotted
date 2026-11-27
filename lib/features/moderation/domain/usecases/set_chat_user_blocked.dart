import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';

class SetChatUserBlocked {
  const SetChatUserBlocked(this._repository);

  final ModerationRepository _repository;

  Future<void> call(String chatId, {required bool blocked}) =>
      _repository.setChatUserBlocked(chatId, blocked: blocked);
}
