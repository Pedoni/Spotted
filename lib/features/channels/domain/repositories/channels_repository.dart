import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/entities/channel_map_pin.dart';

/// Contratto dei canali. Le implementazioni lanciano un `Failure`.
abstract interface class ChannelsRepository {
  /// Pagina di canali, dal più recente, filtrati per nome, topic e luogo
  /// (regione, provincia, comune).
  Future<List<Channel>> getChannels({
    required int offset,
    required int limit,
    String? query,
    String? topicId,
    String? regionName,
    String? provinceCode,
    String? municipalityId,
  });

  /// I pin della mappa: un pin per ogni comune che ha almeno un canale, con le
  /// coordinate e quanti canali ci sono (e il canale, se è uno solo). Stessi
  /// filtri di [getChannels].
  Future<List<ChannelMapPin>> getChannelsMap({
    String? query,
    String? topicId,
    String? regionName,
    String? provinceCode,
    String? municipalityId,
  });

  /// Modifica nome, descrizione, argomento e comune di un canale dell'utente
  /// (lo slug non cambia). `PermissionFailure` se non è il proprietario.
  Future<Channel> updateChannel({
    required String channelId,
    required String name,
    String? description,
    String? topicId,
    String? municipalityId,
  });

  /// Elimina un canale dell'utente con tutto ciò che contiene (spot,
  /// commenti, chat). `PermissionFailure` se non è il proprietario.
  Future<void> deleteChannel(String channelId);

  /// Lancia `NotFoundFailure` se non esiste.
  Future<Channel> getChannelBySlug(String slug);

  /// Canali creati dall'utente loggato.
  Future<List<Channel>> getMyChannels();

  /// Lancia `ConflictFailure` se lo slug è già usato.
  Future<Channel> createChannel({
    required String name,
    required String slug,
    String? description,
    String? municipalityId,
    String? topicId,
  });
}
