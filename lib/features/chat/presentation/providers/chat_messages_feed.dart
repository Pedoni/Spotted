import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/chat/domain/entities/chat_message.dart';
import 'package:spotted/features/chat/presentation/providers/chat_providers.dart';
import 'package:spotted/features/chat/presentation/providers/chats_feed.dart';

part 'chat_messages_feed.g.dart';

/// Messaggi di una chat, dal più recente (infinite scroll verso i più vecchi).
/// Un'istanza per chat. Finché la chat è aperta controlla i nuovi messaggi a
/// intervalli ([chatPollIntervalProvider]).
@riverpod
class ChatMessagesFeed extends _$ChatMessagesFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<ChatMessage>> build(String chatId) async {
    _generation++;
    final interval = ref.watch(chatPollIntervalProvider);
    if (interval != null) {
      final timer = Timer.periodic(
        interval,
        (_) => unawaited(refreshNewest()),
      );
      ref.onDispose(timer.cancel);
    }
    final items = await ref.read(getChatMessagesUseCaseProvider)(
      chatId: chatId,
      offset: 0,
      limit: chatPageSize,
    );
    return PagedList(items: items, hasMore: items.length == chatPageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final more = await ref.read(getChatMessagesUseCaseProvider)(
        chatId: chatId,
        offset: current.items.length,
        limit: chatPageSize,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        PagedList(
          items: [...current.items, ...more],
          hasMore: more.length == chatPageSize,
        ),
      );
    } on Exception {
      if (ref.mounted && generation == _generation) {
        state = AsyncData(
          current.copyWith(isLoadingMore: false, loadMoreFailed: true),
        );
      }
    }
  }

  /// Aggiunge in cima i messaggi arrivati da quando la lista è stata caricata.
  /// Se la richiesta fallisce non fa niente: il prossimo controllo riprova.
  Future<void> refreshNewest() async {
    final current = state.value;
    if (current == null || current.isLoadingMore) return;

    final generation = _generation;
    try {
      final newest = await ref.read(getChatMessagesUseCaseProvider)(
        chatId: chatId,
        offset: 0,
        limit: chatPageSize,
      );
      final latest = state.value;
      if (!ref.mounted || generation != _generation || latest == null) return;
      state = AsyncData(latest.copyWith(items: _merge(newest, latest.items)));
    } on Exception {
      // Ignorato di proposito.
    }
  }

  /// Scrive un messaggio e lo mette in cima alla lista. Se fallisce rilancia
  /// l'errore.
  Future<ChatMessage> send(String content) async {
    final message = await ref.read(sendMessageUseCaseProvider)(
      chatId: chatId,
      content: content,
    );
    final current = state.value;
    if (ref.mounted && current != null) {
      state = AsyncData(
        current.copyWith(items: _merge([message], current.items)),
      );
      // La chat in elenco ha un nuovo ultimo messaggio.
      ref.invalidate(chatsFeedProvider);
    }
    return message;
  }

  /// [fresh] (più recenti) davanti, poi i messaggi già presenti che non sono in
  /// [fresh]: se un messaggio è in entrambi resta una volta sola.
  List<ChatMessage> _merge(List<ChatMessage> fresh, List<ChatMessage> known) {
    final ids = {for (final message in fresh) message.id};
    return [
      ...fresh,
      for (final message in known)
        if (!ids.contains(message.id)) message,
    ];
  }
}
