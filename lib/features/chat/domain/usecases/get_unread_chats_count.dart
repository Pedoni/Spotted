import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';

class GetUnreadChatsCount {
  const GetUnreadChatsCount(this._repository);

  final ChatRepository _repository;

  Future<int> call() => _repository.getUnreadChatsCount();
}
