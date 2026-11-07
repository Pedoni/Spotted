import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';

class GetMyChannels {
  const GetMyChannels(this._repository);

  final ChannelsRepository _repository;

  Future<List<Channel>> call() => _repository.getMyChannels();
}
