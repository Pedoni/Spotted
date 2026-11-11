import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/presentation/providers/channel_spots_feed.dart';

part 'hidden_spots_feed.g.dart';

/// Spot nascosti di un canale, dal più recente (solo per il proprietario).
/// Un'istanza per canale.
@riverpod
class HiddenSpotsFeed extends _$HiddenSpotsFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<Spot>> build(String channelId) async {
    _generation++;
    final items = await ref.read(getHiddenSpotsUseCaseProvider)(
      channelId: channelId,
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
      final more = await ref.read(getHiddenSpotsUseCaseProvider)(
        channelId: channelId,
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
