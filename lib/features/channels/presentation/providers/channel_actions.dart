import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/presentation/providers/channels_feed.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/chat/presentation/providers/chats_feed.dart';
import 'package:spotted/features/spots/presentation/providers/channel_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/followed_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/my_spots_feed.dart';
import 'package:spotted/features/subscriptions/presentation/providers/subscriptions_providers.dart';

part 'channel_actions.g.dart';

/// Modifica ed eliminazione di un canale, con le liste da ricaricare. Resta
/// vivo (`keepAlive`), come `SpotModeration`: dopo l'eliminazione la pagina se
/// ne va e, se il provider si distruggesse a metà, le liste non verrebbero
/// aggiornate. Non tiene dati dell'utente.
@Riverpod(keepAlive: true)
class ChannelActions extends _$ChannelActions {
  @override
  void build() {}

  /// Modifica il canale (lo slug resta lo stesso) e ricarica ciò che lo
  /// mostra. Se fallisce rilancia l'errore e non cambia niente.
  Future<Channel> update({
    required Channel channel,
    required String name,
    String? description,
    String? topicId,
    String? municipalityId,
  }) async {
    final updated = await ref.read(updateChannelUseCaseProvider)(
      channelId: channel.id,
      name: name,
      description: description,
      topicId: topicId,
      municipalityId: municipalityId,
    );
    if (ref.mounted) _refresh(channel.slug);
    return updated;
  }

  /// Elimina il canale con i suoi spot, commenti e chat. Se fallisce rilancia
  /// l'errore e non cambia niente.
  Future<void> delete(Channel channel) async {
    await ref.read(deleteChannelUseCaseProvider)(channel.id);
    if (ref.mounted) _refresh(channel.slug);
  }

  /// Il nome, il luogo e l'esistenza del canale compaiono in più liste: spot
  /// (con il nome del canale), chat e iscrizioni comprese.
  void _refresh(String slug) {
    ref
      ..invalidate(channelDetailProvider(slug))
      ..invalidate(channelsFeedProvider)
      ..invalidate(myChannelsProvider)
      ..invalidate(mySubscribedChannelsProvider)
      ..invalidate(channelSpotsFeedProvider)
      ..invalidate(mySpotsFeedProvider)
      ..invalidate(followedSpotsFeedProvider)
      ..invalidate(chatsFeedProvider);
  }
}
