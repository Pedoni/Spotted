import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';

class GetChannelBySlug {
  const GetChannelBySlug(this._repository);

  final ChannelsRepository _repository;

  Future<Channel> call(String slug) => _repository.getChannelBySlug(slug);
}
