import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/events/data/datasources/events_remote_data_source.dart';
import 'package:spotted/features/events/data/repositories/events_repository_impl.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/domain/repositories/events_repository.dart';
import 'package:spotted/features/events/domain/usecases/create_event.dart';
import 'package:spotted/features/events/domain/usecases/delete_event.dart';
import 'package:spotted/features/events/domain/usecases/get_channel_events.dart';
import 'package:spotted/features/events/domain/usecases/get_event.dart';
import 'package:spotted/features/events/domain/usecases/get_followed_events.dart';
import 'package:spotted/features/events/domain/usecases/update_event.dart';

part 'events_providers.g.dart';

@Riverpod(keepAlive: true)
EventsRepository eventsRepository(Ref ref) {
  return EventsRepositoryImpl(
    EventsRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
GetChannelEvents getChannelEventsUseCase(Ref ref) {
  return GetChannelEvents(ref.watch(eventsRepositoryProvider));
}

@riverpod
GetFollowedEvents getFollowedEventsUseCase(Ref ref) {
  return GetFollowedEvents(ref.watch(eventsRepositoryProvider));
}

@riverpod
GetEvent getEventUseCase(Ref ref) {
  return GetEvent(ref.watch(eventsRepositoryProvider));
}

@riverpod
CreateEvent createEventUseCase(Ref ref) {
  return CreateEvent(ref.watch(eventsRepositoryProvider));
}

@riverpod
UpdateEvent updateEventUseCase(Ref ref) {
  return UpdateEvent(ref.watch(eventsRepositoryProvider));
}

@riverpod
DeleteEvent deleteEventUseCase(Ref ref) {
  return DeleteEvent(ref.watch(eventsRepositoryProvider));
}

/// Un evento (pagina di dettaglio).
@riverpod
Future<ChannelEvent> eventDetail(Ref ref, String eventId) {
  return ref.watch(getEventUseCaseProvider)(eventId);
}
