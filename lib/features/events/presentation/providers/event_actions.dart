import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/presentation/providers/channel_events_feed.dart';
import 'package:spotted/features/events/presentation/providers/events_providers.dart';
import 'package:spotted/features/events/presentation/providers/followed_events_feed.dart';

part 'event_actions.g.dart';

/// Pubblicazione, modifica ed eliminazione degli eventi, con le liste da
/// ricaricare. Resta vivo (`keepAlive`), come `NewsActions`: dopo
/// l'eliminazione la pagina se ne va e, se il provider si distruggesse a metà,
/// le liste non verrebbero aggiornate. Non tiene dati dell'utente.
@Riverpod(keepAlive: true)
class EventActions extends _$EventActions {
  @override
  void build() {}

  /// Pubblica un evento. Se fallisce rilancia l'errore e non cambia niente.
  Future<ChannelEvent> create({
    required String channelId,
    required String title,
    required String description,
    required DateTime startsAt,
    String? location,
    DateTime? endsAt,
  }) async {
    final created = await ref.read(createEventUseCaseProvider)(
      channelId: channelId,
      title: title,
      description: description,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
    );
    if (ref.mounted) _refreshLists();
    return created;
  }

  Future<ChannelEvent> update({
    required String eventId,
    required String title,
    required String description,
    required DateTime startsAt,
    String? location,
    DateTime? endsAt,
  }) async {
    final updated = await ref.read(updateEventUseCaseProvider)(
      eventId: eventId,
      title: title,
      description: description,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
    );
    if (ref.mounted) {
      _refreshLists();
      ref.invalidate(eventDetailProvider(eventId));
    }
    return updated;
  }

  Future<void> delete(String eventId) async {
    await ref.read(deleteEventUseCaseProvider)(eventId);
    // Il dettaglio non si ricarica: la pagina se ne va e l'evento non c'è più.
    if (ref.mounted) _refreshLists();
  }

  /// Le liste che mostrano gli eventi: quelle del canale (un evento può
  /// passare da "Prossimi" a "Passati" cambiando le date, quindi si
  /// ricaricano entrambe) e quella della Home.
  void _refreshLists() {
    ref
      ..invalidate(channelEventsFeedProvider)
      ..invalidate(followedEventsFeedProvider);
  }
}
