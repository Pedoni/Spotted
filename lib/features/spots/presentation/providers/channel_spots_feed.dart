import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';

part 'channel_spots_feed.g.dart';

const spotsPageSize = 20;

/// Spot di un canale, dal più recente (infinite scroll, [spotsPageSize] per
/// pagina). Un'istanza per canale e per testo cercato: senza [query] sono tutti
/// gli spot, con [query] solo quelli che lo contengono.
@riverpod
class ChannelSpotsFeed extends _$ChannelSpotsFeed {
  /// Cresce a ogni ricarica da capo: una `loadMore` partita prima di una
  /// ricarica non deve accodare i suoi risultati alla nuova lista.
  int _generation = 0;

  @override
  Future<PagedList<Spot>> build(String channelId, {String query = ''}) async {
    _generation++;
    final items = await ref.read(getChannelSpotsUseCaseProvider)(
      channelId: channelId,
      offset: 0,
      limit: spotsPageSize,
      query: query,
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
      final more = await ref.read(getChannelSpotsUseCaseProvider)(
        channelId: channelId,
        offset: current.items.length,
        limit: spotsPageSize,
        query: query,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        PagedList(
          items: [...current.items, ...more],
          hasMore: more.length == spotsPageSize,
        ),
      );
    } on Exception {
      // Resta la lista già caricata; la UI offre "Riprova".
      if (ref.mounted && generation == _generation) {
        state = AsyncData(
          current.copyWith(isLoadingMore: false, loadMoreFailed: true),
        );
      }
    }
  }
}
