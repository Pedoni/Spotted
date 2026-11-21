import 'package:spotted/features/channels/domain/entities/channel_map_pin.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';

class GetChannelsMap {
  const GetChannelsMap(this._repository);

  final ChannelsRepository _repository;

  /// I pin della mappa, con gli stessi filtri dell'elenco dei canali. Un testo
  /// fatto di soli spazi non è un filtro.
  Future<List<ChannelMapPin>> call({
    String? query,
    String? topicId,
    String? regionName,
    String? provinceCode,
    String? municipalityId,
  }) {
    final trimmed = query?.trim();
    return _repository.getChannelsMap(
      query: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      topicId: topicId,
      regionName: regionName,
      provinceCode: provinceCode,
      municipalityId: municipalityId,
    );
  }
}
