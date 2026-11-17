import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/events/data/datasources/events_remote_data_source.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/domain/entities/events_when.dart';
import 'package:spotted/features/events/domain/repositories/events_repository.dart';

class EventsRepositoryImpl implements EventsRepository {
  const EventsRepositoryImpl(this._dataSource);

  final EventsRemoteDataSource _dataSource;

  @override
  Future<List<ChannelEvent>> getChannelEvents({
    required String channelId,
    required EventsWhen when,
    required int offset,
    required int limit,
  }) {
    return guardFailures(
      () => _dataSource.getChannelEvents(
        channelId: channelId,
        when: when,
        offset: offset,
        limit: limit,
      ),
    );
  }

  @override
  Future<List<ChannelEvent>> getFollowedEvents({
    required int offset,
    required int limit,
  }) {
    return guardFailures(
      () => _dataSource.getFollowedEvents(offset: offset, limit: limit),
    );
  }

  @override
  Future<ChannelEvent> getEvent(String eventId) {
    return guardFailures(() => _dataSource.getEvent(eventId));
  }

  @override
  Future<ChannelEvent> createEvent({
    required String channelId,
    required String title,
    required String description,
    required DateTime startsAt,
    String? location,
    DateTime? endsAt,
  }) {
    return guardFailures(
      () => _dataSource.createEvent(
        channelId: channelId,
        title: title,
        description: description,
        location: location,
        startsAt: startsAt,
        endsAt: endsAt,
      ),
    );
  }

  @override
  Future<ChannelEvent> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime startsAt,
    String? location,
    DateTime? endsAt,
  }) {
    return guardFailures(
      () => _dataSource.updateEvent(
        eventId: eventId,
        title: title,
        description: description,
        location: location,
        startsAt: startsAt,
        endsAt: endsAt,
      ),
    );
  }

  @override
  Future<void> deleteEvent(String eventId) {
    return guardFailures(() => _dataSource.deleteEvent(eventId));
  }
}
