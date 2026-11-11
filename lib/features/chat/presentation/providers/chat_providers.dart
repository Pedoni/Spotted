import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:spotted/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';
import 'package:spotted/features/chat/domain/usecases/get_chat.dart';
import 'package:spotted/features/chat/domain/usecases/get_chat_messages.dart';
import 'package:spotted/features/chat/domain/usecases/get_chats.dart';
import 'package:spotted/features/chat/domain/usecases/is_spot_author.dart';
import 'package:spotted/features/chat/domain/usecases/reveal_identity.dart';
import 'package:spotted/features/chat/domain/usecases/send_message.dart';
import 'package:spotted/features/chat/domain/usecases/start_chat.dart';
import 'package:spotted/features/chat/presentation/providers/chats_feed.dart';

part 'chat_providers.g.dart';

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  return ChatRepositoryImpl(
    ChatRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
IsSpotAuthor isSpotAuthorUseCase(Ref ref) {
  return IsSpotAuthor(ref.watch(chatRepositoryProvider));
}

@riverpod
StartChat startChatUseCase(Ref ref) {
  return StartChat(ref.watch(chatRepositoryProvider));
}

@riverpod
RevealIdentity revealIdentityUseCase(Ref ref) {
  return RevealIdentity(ref.watch(chatRepositoryProvider));
}

@riverpod
GetChats getChatsUseCase(Ref ref) {
  return GetChats(ref.watch(chatRepositoryProvider));
}

@riverpod
GetChat getChatUseCase(Ref ref) {
  return GetChat(ref.watch(chatRepositoryProvider));
}

@riverpod
GetChatMessages getChatMessagesUseCase(Ref ref) {
  return GetChatMessages(ref.watch(chatRepositoryProvider));
}

@riverpod
SendMessage sendMessageUseCase(Ref ref) {
  return SendMessage(ref.watch(chatRepositoryProvider));
}

/// Ogni quanto si controllano i nuovi messaggi mentre una chat è aperta.
/// `null` spegne il polling (nei test). Si usa il polling perché Realtime
/// richiederebbe di leggere `messages` direttamente e rivelerebbe gli id.
@riverpod
Duration? chatPollInterval(Ref ref) => const Duration(seconds: 5);

/// L'utente loggato è l'autore dello spot (mostra "Chatta" sui commenti). Se la
/// richiesta fallisce l'azione resta nascosta.
@riverpod
Future<bool> isSpotAuthor(Ref ref, String spotId) {
  return ref.watch(isSpotAuthorUseCaseProvider)(spotId);
}

/// Una chat, con lo stato dell'identità.
@riverpod
Future<ChatSummary> chatDetail(Ref ref, String chatId) {
  return ref.watch(getChatUseCaseProvider)(chatId);
}

/// Avvia chat e rivela l'identità, aggiornando le liste. Resta vivo
/// (`keepAlive`): nessuno lo ascolta e, se si distruggesse a metà operazione,
/// le liste non verrebbero aggiornate.
@Riverpod(keepAlive: true)
class ChatActions extends _$ChatActions {
  @override
  void build() {}

  /// Avvia (o riapre) la chat con chi ha scritto il commento e ne restituisce
  /// l'id. Se fallisce rilancia l'errore.
  Future<String> start(String commentId) async {
    final chatId = await ref.read(startChatUseCaseProvider)(commentId);
    if (ref.mounted) ref.invalidate(chatsFeedProvider);
    return chatId;
  }

  /// L'autore mostra il suo username. Non si può annullare. Se fallisce
  /// rilancia l'errore e non cambia niente.
  Future<void> reveal(String chatId) async {
    await ref.read(revealIdentityUseCaseProvider)(chatId);
    if (!ref.mounted) return;
    ref
      ..invalidate(chatDetailProvider(chatId))
      ..invalidate(chatsFeedProvider);
  }
}
