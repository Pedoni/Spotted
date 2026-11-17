import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/events/data/models/event_dto.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/domain/entities/events_when.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gli eventi dei canali. La tabella è chiusa ai client: si usano solo gli RPC
/// (`channel_events_page`, `followed_events_page`, `event_detail`,
/// `create_channel_event`, `update_channel_event`, `delete_channel_event`).
class EventsRemoteDataSource {
  EventsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<ChannelEvent>> getChannelEvents({
    required String channelId,
    required EventsWhen when,
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'channel_events_page',
      params: {
        'p_channel_id': channelId,
        'p_when': when.name,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return _toEvents(rows);
  }

  /// Usa l'RPC `followed_events_page`: i prossimi eventi dei canali seguiti.
  Future<List<ChannelEvent>> getFollowedEvents({
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'followed_events_page',
      params: {'p_limit': limit, 'p_offset': offset},
    );
    return _toEvents(rows);
  }

  Future<ChannelEvent> getEvent(String eventId) async {
    final rows = await _client.rpc<List<dynamic>>(
      'event_detail',
      params: {'p_event_id': eventId},
    );
    return _single(rows);
  }

  Future<ChannelEvent> createEvent({
    required String channelId,
    required String title,
    required String description,
    required DateTime startsAt,
    String? location,
    DateTime? endsAt,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'create_channel_event',
      params: {
        'p_channel_id': channelId,
        'p_title': title,
        'p_description': description,
        'p_location': location,
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_ends_at': endsAt?.toUtc().toIso8601String(),
      },
    );
    return _single(rows);
  }

  Future<ChannelEvent> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime startsAt,
    String? location,
    DateTime? endsAt,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'update_channel_event',
      params: {
        'p_event_id': eventId,
        'p_title': title,
        'p_description': description,
        'p_location': location,
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_ends_at': endsAt?.toUtc().toIso8601String(),
      },
    );
    return _single(rows);
  }

  /// L'RPC risponde `false` se l'evento non esiste.
  Future<void> deleteEvent(String eventId) async {
    final deleted = await _client.rpc<bool>(
      'delete_channel_event',
      params: {'p_event_id': eventId},
    );
    if (!deleted) throw const NotFoundFailure();
  }

  ChannelEvent _single(List<dynamic> rows) {
    final events = _toEvents(rows);
    if (events.isEmpty) throw const NotFoundFailure();
    return events.single;
  }

  List<ChannelEvent> _toEvents(List<dynamic> rows) => rows
      .cast<Map<String, dynamic>>()
      .map((row) => EventDto.fromJson(row).toEntity())
      .toList();
}
