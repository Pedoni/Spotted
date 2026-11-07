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
  });

  final List<Channel> items;
  final bool hasMore;
  final bool isLoadingMore;

  PagedChannels copyWith({
    List<Channel>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PagedChannels(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [items, hasMore, isLoadingMore];
}

/// Lista paginata dei canali (infinite scroll, [channelsPageSize] per pagina).
@riverpod
class ChannelsFeed extends _$ChannelsFeed {
  @override
  Future<PagedChannels> build() async {
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
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final more = await ref.read(getChannelsUseCaseProvider)(
        offset: current.items.length,
        limit: channelsPageSize,
        query: filter.query,
        topicId: filter.topicId,
      );
      if (!ref.mounted) return;
      state = AsyncData(
        PagedChannels(
          items: [...current.items, ...more],
          hasMore: more.length == channelsPageSize,
        ),
      );
    } on Exception {
      // Resta la lista già caricata e si smette di caricare altre pagine
      // (altrimenti il ricaricamento automatico ripeterebbe l'errore in loop);
      // il pull-to-refresh riparte da capo.
      if (ref.mounted) state = AsyncData(current.copyWith(hasMore: false));
    }
  }
}
