import 'dart:math';

import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/channel_slug.dart';
import 'package:spotted/features/channels/domain/channel_validators.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';

class CreateChannel {
  CreateChannel(this._repository, [this._random]);

  static const maxAttempts = 5;

  final ChannelsRepository _repository;
  final Random? _random;

  /// Crea il canale generando lo slug dal nome. Se lo slug è già usato prova
  /// con un suffisso casuale, fino a [maxAttempts] tentativi.
  Future<Channel> call({
    required String name,
    String? description,
    String? municipalityId,
    String? topicId,
  }) async {
    if (!ChannelValidators.isValidName(name) ||
        !ChannelValidators.isValidDescription(description ?? '')) {
      throw const ValidationFailure();
    }

    final baseSlug = ChannelSlug.slugify(name);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final slug = attempt == 0
          ? baseSlug
          : '$baseSlug-${ChannelSlug.randomSuffix(_random)}';
      try {
        return await _repository.createChannel(
          name: name.trim(),
          slug: slug,
          description: _nullIfBlank(description),
          municipalityId: _nullIfBlank(municipalityId),
          topicId: topicId,
        );
      } on ConflictFailure {
        if (attempt == maxAttempts - 1) rethrow;
      }
    }
    throw const ConflictFailure();
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
