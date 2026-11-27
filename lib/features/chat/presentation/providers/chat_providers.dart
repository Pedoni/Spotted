import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:spotted/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';
import 'package:spotted/features/chat/domain/usecases/get_chat.dart';
import 'package:spotted/features/chat/domain/usecases/get_chat_messages.dart';
import 'package:spotted/features/chat/domain/usecases/get_chats.dart';
import 'package:spotted/features/chat/domain/usecases/get_unread_chats_count.dart';
import 'package:spotted/features/chat/domain/usecases/is_spot_author.dart';
import 'package:spotted/features/chat/domain/usecases/mark_chat_read.dart';
import 'package:spotted/features/chat/domain/usecases/reveal_identity.dart';
import 'package:spotted/features/chat/domain/usecases/send_message.dart';
import 'package:spotted/features/chat/domain/usecases/start_channel_chat.dart';
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
StartChannelChat startChannelChatUseCase(Ref ref) {
  return StartChannelChat(ref.watch(chatRepositoryProvider));
}

@riverpod
MarkChatRead markChatReadUseCase(Ref ref) {
  return MarkChatRead(ref.watch(chatRepositoryProvider));
}

@riverpod
GetUnreadChatsCount getUnreadChatsCountUseCase(Ref ref) {
  return GetUnreadChatsCount(ref.watch(chatRepositoryProvider));
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

/// Ogni quanto si controlla se ci sono chat non lette (il numero sull'icona
/// Chat). `null` spegne il controllo periodico (nei test).
@riverpod
Duration? unreadPollInterval(Ref ref) => const Duration(seconds: 30);

/// Quante chat hanno messaggi non letti: il numero sull'icona Chat. Si
/// controlla a intervalli; se il numero cambia si ricarica anche l'elenco delle
/// chat, così le chat non lette sono in grassetto. Se la richiesta fallisce non
/// si mostra niente (il prossimo controllo riprova).
@riverpod
class UnreadChats extends _$UnreadChats {
  int? _last;

  @override
  Future<int> build() async {
    final interval = ref.watch(unreadPollIntervalProvider);
    if (interval != null) {
      final timer = Timer.periodic(interval, (_) => ref.invalidateSelf());
      ref.onDispose(timer.cancel);
    }
    final count = await ref.watch(getUnreadChatsCountUseCaseProvider)();
    final last = _last;
    _last = count;
    if (last != null && last != count) {
      // Su una nuova richiesta la lista si aggiorna da sola.
      unawaited(
        Future.microtask(() {
          if (ref.mounted) ref.invalidate(chatsFeedProvider);
        }),
      );
    }
    return count;
  }
}

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

  /// Segna la chat come letta e aggiorna il numero sull'icona e l'elenco. Se
  /// fallisce non cambia niente: la chat resterà non letta fino alla prossima
  /// apertura.
  Future<void> markRead(String chatId) async {
    try {
      await ref.read(markChatReadUseCaseProvider)(chatId);
    } on Exception {
      return;
    }
    if (!ref.mounted) return;
    ref
      ..invalidate(unreadChatsProvider)
      ..invalidate(chatsFeedProvider);
  }

  /// Apre la chat con un canale (la crea se non c'è) e ne restituisce l'id.
  /// Se fallisce rilancia l'errore.
  Future<String> startChannel(String channelId) async {
    final chatId = await ref.read(startChannelChatUseCaseProvider)(channelId);
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
