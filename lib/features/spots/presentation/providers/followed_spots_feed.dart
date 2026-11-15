import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/spots/domain/entities/spot_with_channel.dart';
import 'package:spotted/features/spots/presentation/providers/channel_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';

part 'followed_spots_feed.g.dart';

/// Gli spot dei canali seguiti, dal più recente (la Home).
@riverpod
class FollowedSpotsFeed extends _$FollowedSpotsFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<SpotWithChannel>> build() async {
    _generation++;
    final items = await ref.read(getFollowedSpotsUseCaseProvider)(
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
      final more = await ref.read(getFollowedSpotsUseCaseProvider)(
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
}
