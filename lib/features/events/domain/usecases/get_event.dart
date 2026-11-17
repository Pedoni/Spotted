import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/domain/repositories/events_repository.dart';

class GetEvent {
  const GetEvent(this._repository);

  final EventsRepository _repository;

  Future<ChannelEvent> call(String eventId) => _repository.getEvent(eventId);
}
