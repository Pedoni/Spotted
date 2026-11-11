import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';

class GetChats {
  const GetChats(this._repository);

  final ChatRepository _repository;

  Future<List<ChatSummary>> call({required int offset, required int limit}) =>
      _repository.getChats(offset: offset, limit: limit);
}
