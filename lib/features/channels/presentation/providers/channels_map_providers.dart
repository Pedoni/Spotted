import 'package:flutter_map/flutter_map.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/entities/channel_map_pin.dart';
import 'package:spotted/features/channels/domain/usecases/get_channels_map.dart';
import 'package:spotted/features/channels/presentation/providers/channels_feed.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';

part 'channels_map_providers.g.dart';

/// Come si vedono i canali in Esplora: l'elenco o la mappa.
enum ChannelsViewMode { list, map }

/// La vista scelta in Esplora. Non si ricorda a lungo: si riparte dall'elenco.
@riverpod
class ChannelsViewModeController extends _$ChannelsViewModeController {
  @override
  ChannelsViewMode build() => ChannelsViewMode.list;

  // The setter-like method keeps the call sites explicit.
  // ignore: use_setters_to_change_properties
  void select(ChannelsViewMode mode) => state = mode;
}

@riverpod
GetChannelsMap getChannelsMapUseCase(Ref ref) {
  return GetChannelsMap(ref.watch(channelsRepositoryProvider));
}

/// I pin della mappa, con gli stessi filtri dell'elenco (testo, argomento,
/// luogo): cambiarli ricarica i pin.
@riverpod
Future<List<ChannelMapPin>> channelsMapPins(Ref ref) {
  final filter = ref.watch(channelFilterProvider);
  return ref.watch(getChannelsMapUseCaseProvider)(
    query: filter.query,
    topicId: filter.topicId,
    regionName: filter.regionName,
    provinceCode: filter.provinceCode,
    municipalityId: filter.municipality?.istatCode,
  );
}

/// Da dove arrivano i riquadri della mappa. Senza dati dell'utente, quindi
/// resta in memoria; nei test si sostituisce con uno che non scarica niente.
@Riverpod(keepAlive: true)
TileProvider mapTileProvider(Ref ref) => NetworkTileProvider();

/// I canali di un comune (l'elenco che si apre toccando un pin con più
/// canali), dal più recente, con i filtri di Esplora (testo, argomento) e le
/// pagine di sempre. Un'istanza per comune.
@riverpod
class MunicipalityChannelsFeed extends _$MunicipalityChannelsFeed {
  /// Vedi `ChannelsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<Channel>> build(String municipalityId) async {
    _generation++;
    final filter = ref.watch(channelFilterProvider);
    final items = await ref.read(getChannelsUseCaseProvider)(
      offset: 0,
      limit: channelsPageSize,
      query: filter.query,
      topicId: filter.topicId,
      regionName: filter.regionName,
      provinceCode: filter.provinceCode,
      municipalityId: municipalityId,
    );
    return PagedList(items: items, hasMore: items.length == channelsPageSize);
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
        municipalityId: municipalityId,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        PagedList(
          items: [...current.items, ...more],
          hasMore: more.length == channelsPageSize,
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
