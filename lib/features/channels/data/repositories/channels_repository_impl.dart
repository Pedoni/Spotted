import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/channels/data/datasources/channels_remote_data_source.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';

class ChannelsRepositoryImpl implements ChannelsRepository {
  const ChannelsRepositoryImpl(this._dataSource);

  final ChannelsRemoteDataSource _dataSource;

  @override
  Future<List<Channel>> getChannels({
    required int offset,
    required int limit,
    String? query,
    String? topicId,
  }) {
    return guardFailures(
      () => _dataSource.getChannels(
        offset: offset,
        limit: limit,
        query: query,
        topicId: topicId,
      ),
    );
  }

  @override
  Future<Channel> getChannelBySlug(String slug) {
    return guardFailures(() => _dataSource.getChannelBySlug(slug));
  }

  @override
  Future<List<Channel>> getMyChannels() {
    return guardFailures(_dataSource.getMyChannels);
  }

  @override
  Future<Channel> createChannel({
    required String name,
    required String slug,
    String? description,
    String? municipalityId,
    String? topicId,
  }) {
    return guardFailures(
      () => _dataSource.createChannel(
        name: name,
        slug: slug,
        description: description,
        municipalityId: municipalityId,
        topicId: topicId,
      ),
    );
  }
}
