import 'package:spotted/features/channels/domain/entities/channel.dart';

/// Contratto dei canali. Le implementazioni lanciano un `Failure`.
abstract interface class ChannelsRepository {
  /// Pagina di canali, dal più recente, filtrati per nome e/o topic.
  Future<List<Channel>> getChannels({
    required int offset,
    required int limit,
    String? query,
    String? topicId,
  });

  /// Lancia `NotFoundFailure` se non esiste.
  Future<Channel> getChannelBySlug(String slug);

  /// Canali creati dall'utente loggato.
  Future<List<Channel>> getMyChannels();

  /// Lancia `ConflictFailure` se lo slug è già usato.
  Future<Channel> createChannel({
    required String name,
    required String slug,
    String? description,
    String? place,
    String? topicId,
  });
}
