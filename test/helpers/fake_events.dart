import 'dart:async';

import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/domain/entities/events_when.dart';
import 'package:spotted/features/events/domain/repositories/events_repository.dart';

/// Un evento di prova. Senza [past] è tra [i] giorni (futuro); con [past] è
/// finito [i] giorni fa.
ChannelEvent makeEvent(
  int i, {
  bool past = false,
  String channelId = 'c1',
  String channelName = 'Canale 1',
  String channelSlug = 'canale-1',
  String? title,
  String? description,
  String? location,
  DateTime? startsAt,
  DateTime? endsAt,
}) {
  final now = DateTime.now();
  return ChannelEvent(
    id: 'e$i',
    channelId: channelId,
    channelName: channelName,
    channelSlug: channelSlug,
    title: title ?? 'Evento $i',
    description: description ?? "Descrizione dell'evento $i",
    location: location,
    startsAt:
        startsAt ??
        (past ? now.subtract(Duration(days: i)) : now.add(Duration(days: i))),
    endsAt: endsAt,
    createdAt: DateTime(2026).subtract(Duration(minutes: i)),
  );
}

/// Eventi in memoria. Come l'RPC: `upcoming` sono quelli in corso o futuri
/// (dal più vicino), `past` quelli finiti (dal più recente). Un evento senza
/// fine dura 3 ore. Se [gate] è impostato, le pagine successive alla prima
/// restano in attesa finché non si completa.
class FakeEventsRepository implements EventsRepository {
  FakeEventsRepository({List<ChannelEvent>? events}) : events = events ?? [];

  List<ChannelEvent> events;

  /// I prossimi eventi dei canali seguiti (la Home).
  List<ChannelEvent> followed = [];
  Failure? followedError;
  Completer<void>? followedGate;
  final followedCalls = <({int offset, int limit})>[];
  Failure? listError;
  Failure? detailError;
  Failure? createError;
  Failure? updateError;
  Failure? deleteError;
  Completer<void>? gate;

  final listCalls =
      <({String channelId, EventsWhen when, int offset, int limit})>[];
  final createCalls = <Map<String, Object?>>[];
  final updateCalls = <Map<String, Object?>>[];
  final deleteCalls = <String>[];

  static DateTime _end(ChannelEvent e) =>
      e.endsAt ?? e.startsAt.add(const Duration(hours: 3));

  @override
  Future<List<ChannelEvent>> getChannelEvents({
    required String channelId,
    required EventsWhen when,
    required int offset,
    required int limit,
  }) async {
    listCalls.add((
      channelId: channelId,
      when: when,
      offset: offset,
      limit: limit,
    ));
    if (listError != null) throw listError!;
    if (offset > 0 && gate != null) await gate!.future;
    final now = DateTime.now();
    final inChannel = events.where((e) => e.channelId == channelId);
    final selected = when == EventsWhen.upcoming
        ? (inChannel.where((e) => !_end(e).isBefore(now)).toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt)))
        : (inChannel.where((e) => _end(e).isBefore(now)).toList()
            ..sort((a, b) => b.startsAt.compareTo(a.startsAt)));
    return selected.skip(offset).take(limit).toList();
  }

  @override
  Future<List<ChannelEvent>> getFollowedEvents({
    required int offset,
    required int limit,
  }) async {
    followedCalls.add((offset: offset, limit: limit));
    if (followedError != null) throw followedError!;
    if (offset > 0 && followedGate != null) await followedGate!.future;
    return followed.skip(offset).take(limit).toList();
  }

  @override
  Future<ChannelEvent> getEvent(String eventId) async {
    if (detailError != null) throw detailError!;
    return events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw const NotFoundFailure(),
    );
  }

  @override
  Future<ChannelEvent> createEvent({
    required String channelId,
    required String title,
    required String description,
    required DateTime startsAt,
    String? location,
    DateTime? endsAt,
  }) async {
    createCalls.add({
      'channelId': channelId,
      'title': title,
      'description': description,
      'location': location,
      'startsAt': startsAt,
      'endsAt': endsAt,
    });
    if (createError != null) throw createError!;
    final created = makeEvent(
      100 + createCalls.length,
      channelId: channelId,
      title: title,
      description: description,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
    );
    events = [created, ...events];
    return created;
  }

  @override
  Future<ChannelEvent> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime startsAt,
    String? location,
    DateTime? endsAt,
  }) async {
    updateCalls.add({
      'eventId': eventId,
      'title': title,
      'description': description,
      'location': location,
      'startsAt': startsAt,
      'endsAt': endsAt,
    });
    if (updateError != null) throw updateError!;
    final old = events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw const NotFoundFailure(),
    );
    final updated = ChannelEvent(
      id: old.id,
      channelId: old.channelId,
      channelName: old.channelName,
      channelSlug: old.channelSlug,
      title: title,
      description: description,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
      createdAt: old.createdAt,
    );
    events = [
      for (final e in events)
        if (e.id == eventId) updated else e,
    ];
    return updated;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    deleteCalls.add(eventId);
    if (deleteError != null) throw deleteError!;
    final before = events.length;
    events = events.where((e) => e.id != eventId).toList();
    if (events.length == before) throw const NotFoundFailure();
  }
}
