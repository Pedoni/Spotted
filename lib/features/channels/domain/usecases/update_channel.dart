import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/channel_validators.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';

/// Modifica un canale dell'utente. Lo slug (l'indirizzo) non cambia.
class UpdateChannel {
  const UpdateChannel(this._repository);

  final ChannelsRepository _repository;

  Future<Channel> call({
    required String channelId,
    required String name,
    String? description,
    String? topicId,
    String? municipalityId,
  }) {
    if (!ChannelValidators.isValidName(name) ||
        !ChannelValidators.isValidDescription(description ?? '')) {
      throw const ValidationFailure();
    }
    return _repository.updateChannel(
      channelId: channelId,
      name: name.trim(),
      description: _nullIfBlank(description),
      topicId: topicId,
      municipalityId: _nullIfBlank(municipalityId),
    );
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
