import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/presentation/providers/channel_events_feed.dart';
import 'package:spotted/features/events/presentation/providers/events_providers.dart';

part 'followed_events_feed.g.dart';

/// I prossimi eventi dei canali seguiti, dal più vicino (la Home). Dipende
/// dalle iscrizioni dell'utente, quindi non resta in vita (`autoDispose`).
@riverpod
class FollowedEventsFeed extends _$FollowedEventsFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<ChannelEvent>> build() async {
    _generation++;
    final items = await ref.read(getFollowedEventsUseCaseProvider)(
      offset: 0,
      limit: eventsPageSize,
    );
    return PagedList(items: items, hasMore: items.length == eventsPageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final more = await ref.read(getFollowedEventsUseCaseProvider)(
        offset: current.items.length,
        limit: eventsPageSize,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        PagedList(
          items: [...current.items, ...more],
          hasMore: more.length == eventsPageSize,
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
