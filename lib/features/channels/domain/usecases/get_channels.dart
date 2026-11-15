import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';

class GetChannels {
  const GetChannels(this._repository);

  final ChannelsRepository _repository;

  Future<List<Channel>> call({
    required int offset,
    required int limit,
    String? query,
    String? topicId,
    String? regionName,
    String? provinceCode,
    String? municipalityId,
  }) {
    final trimmed = query?.trim();
    return _repository.getChannels(
      offset: offset,
      limit: limit,
      query: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      topicId: topicId,
      regionName: regionName,
      provinceCode: provinceCode,
      municipalityId: municipalityId,
    );
  }
}
