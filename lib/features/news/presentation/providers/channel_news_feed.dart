import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/presentation/providers/news_providers.dart';

part 'channel_news_feed.g.dart';

const newsPageSize = 20;

/// Le news di un canale, dalla più recente (infinite scroll, [newsPageSize]
/// per pagina). Un'istanza per canale.
@riverpod
class ChannelNewsFeed extends _$ChannelNewsFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<ChannelNews>> build(String channelId) async {
    _generation++;
    final items = await ref.read(getChannelNewsUseCaseProvider)(
      channelId: channelId,
      offset: 0,
      limit: newsPageSize,
    );
    return PagedList(items: items, hasMore: items.length == newsPageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final more = await ref.read(getChannelNewsUseCaseProvider)(
        channelId: channelId,
        offset: current.items.length,
        limit: newsPageSize,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        PagedList(
          items: [...current.items, ...more],
          hasMore: more.length == newsPageSize,
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
