import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:spotted/features/chat/domain/entities/chat_message.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._dataSource);

  final ChatRemoteDataSource _dataSource;

  @override
  Future<bool> isSpotAuthor(String spotId) {
    return guardFailures(() => _dataSource.isSpotAuthor(spotId));
  }

  @override
  Future<String> startChat(String commentId) {
    return guardFailures(() => _dataSource.startChat(commentId));
  }

  @override
  Future<String> startChannelChat(String channelId) {
    return guardFailures(() => _dataSource.startChannelChat(channelId));
  }

  @override
  Future<void> markChatRead(String chatId) {
    return guardFailures(() => _dataSource.markChatRead(chatId));
  }

  @override
  Future<int> getUnreadChatsCount() {
    return guardFailures(_dataSource.getUnreadChatsCount);
  }

  @override
  Future<void> revealIdentity(String chatId) {
    return guardFailures(() => _dataSource.revealIdentity(chatId));
  }

  @override
  Future<List<ChatSummary>> getChats({
    required int offset,
    required int limit,
  }) {
    return guardFailures(
      () => _dataSource.getChats(offset: offset, limit: limit),
    );
  }

  @override
  Future<ChatSummary> getChat(String chatId) {
    return guardFailures(() => _dataSource.getChat(chatId));
  }

  @override
  Future<List<ChatMessage>> getMessages({
    required String chatId,
    required int offset,
    required int limit,
  }) {
    return guardFailures(
      () => _dataSource.getMessages(
        chatId: chatId,
        offset: offset,
        limit: limit,
      ),
    );
  }

  @override
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String content,
  }) {
    return guardFailures(
      () => _dataSource.sendMessage(chatId: chatId, content: content),
    );
  }
}
