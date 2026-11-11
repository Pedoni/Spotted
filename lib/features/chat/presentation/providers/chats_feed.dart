import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/presentation/providers/chat_providers.dart';

part 'chats_feed.g.dart';

const chatPageSize = 20;

/// Le chat dell'utente, dalla più recente (infinite scroll, [chatPageSize] per
/// pagina).
@riverpod
class ChatsFeed extends _$ChatsFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<ChatSummary>> build() async {
    _generation++;
    final items = await ref.read(getChatsUseCaseProvider)(
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
      final more = await ref.read(getChatsUseCaseProvider)(
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
}
