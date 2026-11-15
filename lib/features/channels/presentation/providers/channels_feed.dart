import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';

part 'channels_feed.g.dart';

const channelsPageSize = 20;

/// Il comune scelto come filtro: il codice ISTAT e il testo da mostrare.
class MunicipalityFilter extends Equatable {
  const MunicipalityFilter({required this.istatCode, required this.label});

  final String istatCode;
  final String label;

  @override
  List<Object?> get props => [istatCode, label];
}

/// I filtri della lista dei canali: il testo cercato nel nome, l'argomento e il
/// luogo (regione, provincia, comune). Il luogo è coerente: se c'è un comune
/// ci sono anche la sua provincia e la sua regione.
class ChannelFilterState extends Equatable {
  const ChannelFilterState({
    this.query = '',
    this.topicId,
    this.regionName,
    this.provinceCode,
    this.provinceLabel,
    this.municipality,
  });

  final String query;
  final String? topicId;
  final String? regionName;
  final String? provinceCode;

  /// Il testo da mostrare per la provincia ("Pisa (PI)").
  final String? provinceLabel;
  final MunicipalityFilter? municipality;

  /// Quanti filtri del foglio sono attivi (il testo cercato non conta).
  int get activeCount => [
    topicId,
    regionName,
    provinceCode,
    municipality,
  ].where((value) => value != null).length;

  bool get hasFilters => activeCount > 0;

  /// Gli stessi filtri con un altro testo cercato.
  ChannelFilterState withQuery(String value) => ChannelFilterState(
    query: value,
    topicId: topicId,
    regionName: regionName,
    provinceCode: provinceCode,
    provinceLabel: provinceLabel,
    municipality: municipality,
  );

  /// Gli stessi filtri del foglio con [other] (testo cercato escluso).
  ChannelFilterState withFiltersOf(ChannelFilterState other) =>
      ChannelFilterState(
        query: query,
        topicId: other.topicId,
        regionName: other.regionName,
        provinceCode: other.provinceCode,
        provinceLabel: other.provinceLabel,
        municipality: other.municipality,
      );

  @override
  List<Object?> get props => [
    query,
    topicId,
    regionName,
    provinceCode,
    provinceLabel,
    municipality,
  ];
}

/// Filtri correnti della lista canali: cambiarli ricarica il feed.
@riverpod
class ChannelFilter extends _$ChannelFilter {
  @override
  ChannelFilterState build() => const ChannelFilterState();

  void setQuery(String query) {
    state = state.withQuery(query);
  }

  /// Applica i filtri scelti nel foglio, tenendo il testo cercato.
  void apply(ChannelFilterState filters) {
    state = state.withFiltersOf(filters);
  }

  /// Toglie tutti i filtri del foglio, tenendo il testo cercato.
  void clearFilters() {
    state = state.withFiltersOf(const ChannelFilterState());
  }
}

typedef PagedChannels = PagedList<Channel>;

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
      regionName: filter.regionName,
      provinceCode: filter.provinceCode,
      municipalityId: filter.municipality?.istatCode,
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
        regionName: filter.regionName,
        provinceCode: filter.provinceCode,
        municipalityId: filter.municipality?.istatCode,
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
