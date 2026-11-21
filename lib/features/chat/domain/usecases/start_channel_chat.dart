import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';

class StartChannelChat {
  const StartChannelChat(this._repository);

  final ChatRepository _repository;

  Future<String> call(String channelId) =>
      _repository.startChannelChat(channelId);
}
