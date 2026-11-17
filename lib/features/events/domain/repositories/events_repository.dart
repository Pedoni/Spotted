import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/domain/entities/events_when.dart';

/// Contratto degli eventi dei canali. Le implementazioni lanciano un `Failure`.
abstract interface class EventsRepository {
  /// Pagina di eventi di un canale: [when] sceglie quelli in corso o futuri
  /// (dal più vicino) o quelli già finiti (dal più recente).
  Future<List<ChannelEvent>> getChannelEvents({
    required String channelId,
    required EventsWhen when,
    required int offset,
    required int limit,
  });

  /// I prossimi eventi (in corso o futuri) dei canali seguiti, dal più
  /// vicino.
  Future<List<ChannelEvent>> getFollowedEvents({
    required int offset,
    required int limit,
  });

  /// Un evento. Lancia `NotFoundFailure` se non esiste.
  Future<ChannelEvent> getEvent(String eventId);

  /// Pubblica un evento. Solo il proprietario del canale (altrimenti
  /// `PermissionFailure`).
  Future<ChannelEvent> createEvent({
    required String channelId,
    required String title,
    required String description,
    required DateTime startsAt,
    String? location,
    DateTime? endsAt,
  });

  /// Modifica un evento. Lancia `NotFoundFailure` se non esiste e
  /// `PermissionFailure` se chi chiama non è il proprietario.
  Future<ChannelEvent> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime startsAt,
    String? location,
    DateTime? endsAt,
  });

  /// Elimina un evento. Lancia `NotFoundFailure` se non esiste e
  /// `PermissionFailure` se chi chiama non è il proprietario.
  Future<void> deleteEvent(String eventId);
}
