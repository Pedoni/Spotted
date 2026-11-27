import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';

class IsChatUserBlocked {
  const IsChatUserBlocked(this._repository);

  final ModerationRepository _repository;

  Future<bool> call(String chatId) => _repository.isChatUserBlocked(chatId);
}
