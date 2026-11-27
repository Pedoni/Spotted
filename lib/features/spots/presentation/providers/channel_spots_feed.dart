import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';

part 'channel_spots_feed.g.dart';

const spotsPageSize = 20;

/// La chiave di un insieme di tag: i nomi tecnici in ordine alfabetico,
/// separati da virgola (non contengono mai virgole).
String spotTagsKey(Iterable<String> tags) => ([...tags]..sort()).join(',');

/// L'inverso di [spotTagsKey].
List<String> spotTagsFromKey(String key) =>
    key.isEmpty ? const [] : key.split(',');

/// Spot di un canale, dal più recente (infinite scroll, [spotsPageSize] per
/// pagina). Un'istanza per canale, per testo cercato e per tag scelti: senza
/// [query] né [tags] sono tutti gli spot, con [query] solo quelli che lo
/// contengono, con [tags] solo quelli che hanno almeno uno di quei tag.
///
/// [tags] è una stringa (i nomi tecnici separati da virgola, in ordine
/// alfabetico, vedi [spotTagsKey]) e non una lista, perché la chiave di un
/// provider deve potersi confrontare: due liste uguali non sarebbero la stessa
/// chiave.
@riverpod
class ChannelSpotsFeed extends _$ChannelSpotsFeed {
  /// Cresce a ogni ricarica da capo: una `loadMore` partita prima di una
  /// ricarica non deve accodare i suoi risultati alla nuova lista.
  int _generation = 0;

  @override
  Future<PagedList<Spot>> build(
    String channelId, {
    String query = '',
    String tags = '',
  }) async {
    _generation++;
    final items = await ref.read(getChannelSpotsUseCaseProvider)(
      channelId: channelId,
      offset: 0,
      limit: spotsPageSize,
      query: query,
      tags: spotTagsFromKey(tags),
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
        tags: spotTagsFromKey(tags),
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
