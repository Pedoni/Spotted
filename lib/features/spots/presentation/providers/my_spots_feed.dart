import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/spots/domain/entities/spot_with_channel.dart';
import 'package:spotted/features/spots/presentation/providers/channel_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/followed_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';

part 'my_spots_feed.g.dart';

/// Gli spot scritti dall'utente loggato, dal più recente.
@riverpod
class MySpotsFeed extends _$MySpotsFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<SpotWithChannel>> build() async {
    _generation++;
    final items = await ref.read(getMySpotsUseCaseProvider)(
      offset: 0,
      limit: spotsPageSize,
    );
    return PagedList(items: items, hasMore: items.length == spotsPageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final more = await ref.read(getMySpotsUseCaseProvider)(
        offset: current.items.length,
        limit: spotsPageSize,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        PagedList(
          items: [...current.items, ...more],
          hasMore: more.length == spotsPageSize,
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

  /// Cancella lo spot. Se fallisce rilancia l'errore e la lista non cambia.
  Future<void> delete(String spotId) async {
    await ref.read(deleteSpotUseCaseProvider)(spotId);
    if (!ref.mounted) return;
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          items: [
            for (final item in current.items)
              if (item.spot.id != spotId) item,
          ],
        ),
      );
    }
    // Il feed dei canali non deve più mostrarlo.
    ref
      ..invalidate(channelSpotsFeedProvider)
      ..invalidate(followedSpotsFeedProvider);
  }
}
