import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';

part 'channels_feed.g.dart';

const channelsPageSize = 20;

class ChannelFilterState extends Equatable {
  const ChannelFilterState({this.query = '', this.topicId});

  final String query;
  final String? topicId;

  @override
  List<Object?> get props => [query, topicId];
}

/// Filtri correnti della lista canali: cambiarli ricarica il feed.
@riverpod
class ChannelFilter extends _$ChannelFilter {
  @override
  ChannelFilterState build() => const ChannelFilterState();

  void setQuery(String query) {
    state = ChannelFilterState(query: query, topicId: state.topicId);
  }

  /// `null` toglie il filtro per topic.
  void setTopic(String? topicId) {
    state = ChannelFilterState(query: state.query, topicId: topicId);
  }
}

class PagedChannels extends Equatable {
  const PagedChannels({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<Channel> items;
  final bool hasMore;
  final bool isLoadingMore;

  /// L'ultimo caricamento di una pagina successiva è fallito: la UI mostra
  /// "Riprova" invece di ritentare da sola in loop.
  final bool loadMoreFailed;

  PagedChannels copyWith({
    List<Channel>? items,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return PagedChannels(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }

  @override
  List<Object?> get props => [items, hasMore, isLoadingMore, loadMoreFailed];
}

/// Lista paginata dei canali (infinite scroll, [channelsPageSize] per pagina).
@riverpod
class ChannelsFeed extends _$ChannelsFeed {
  /// Cresce a ogni ricarica da capo: una `loadMore` partita prima di una
  /// ricarica (es. cambio filtro) non deve accodare i suoi risultati alla
  /// nuova lista.
  int _generation = 0;

  @override
  Future<PagedChannels> build() async {
    _generation++;
    final filter = ref.watch(channelFilterProvider);
    final items = await ref.read(getChannelsUseCaseProvider)(
      offset: 0,
      limit: channelsPageSize,
      query: filter.query,
      topicId: filter.topicId,
    );
    return PagedChannels(
      items: items,
      hasMore: items.length == channelsPageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final filter = ref.read(channelFilterProvider);
    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final more = await ref.read(getChannelsUseCaseProvider)(
        offset: current.items.length,
        limit: channelsPageSize,
        query: filter.query,
        topicId: filter.topicId,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        PagedChannels(
          items: [...current.items, ...more],
          hasMore: more.length == channelsPageSize,
        ),
      );
    } on Exception {
      // Resta la lista già caricata; la UI offre "Riprova" (non ritenta da
      // sola, altrimenti ripeterebbe l'errore in loop).
      if (ref.mounted && generation == _generation) {
        state = AsyncData(
          current.copyWith(isLoadingMore: false, loadMoreFailed: true),
        );
      }
    }
  }
}
