import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';

/// Elimina un canale dell'utente con tutto ciò che contiene.
class DeleteChannel {
  const DeleteChannel(this._repository);

  final ChannelsRepository _repository;

  Future<void> call(String channelId) => _repository.deleteChannel(channelId);
}
