import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/domain/entities/events_when.dart';
import 'package:spotted/features/events/presentation/providers/events_providers.dart';

part 'channel_events_feed.g.dart';

const eventsPageSize = 20;

/// Gli eventi di un canale (infinite scroll, [eventsPageSize] per pagina): un
/// elenco per canale e per periodo. `upcoming` dal più vicino, `past` dal più
/// recente.
@riverpod
class ChannelEventsFeed extends _$ChannelEventsFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<ChannelEvent>> build(
    String channelId,
    EventsWhen when,
  ) async {
    _generation++;
    final items = await ref.read(getChannelEventsUseCaseProvider)(
      channelId: channelId,
      when: when,
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
      final more = await ref.read(getChannelEventsUseCaseProvider)(
        channelId: channelId,
        when: when,
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
