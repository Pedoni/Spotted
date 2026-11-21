import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/channel_validators.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';

/// Modifica un canale dell'utente. Lo slug (l'indirizzo) non cambia. Il comune
/// è obbligatorio.
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
    // Modificare un canale vuol dire indicarne la città, anche se prima non ce
    // l'aveva (i canali nati quando era facoltativa).
    if (!ChannelValidators.isValidName(name) ||
        !ChannelValidators.isValidDescription(description ?? '') ||
        _nullIfBlank(municipalityId) == null) {
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
