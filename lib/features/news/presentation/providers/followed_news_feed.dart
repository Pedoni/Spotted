import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/presentation/providers/channel_news_feed.dart';
import 'package:spotted/features/news/presentation/providers/news_providers.dart';

part 'followed_news_feed.g.dart';

/// Le news dei canali seguiti, dalla più recente (la Home). Dipende dalle
/// iscrizioni dell'utente, quindi non resta in vita (`autoDispose`).
@riverpod
class FollowedNewsFeed extends _$FollowedNewsFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<ChannelNews>> build() async {
    _generation++;
    final items = await ref.read(getFollowedNewsUseCaseProvider)(
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
      final more = await ref.read(getFollowedNewsUseCaseProvider)(
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
