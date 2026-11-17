import 'package:spotted/features/events/domain/repositories/events_repository.dart';

class DeleteEvent {
  const DeleteEvent(this._repository);

  final EventsRepository _repository;

  Future<void> call(String eventId) => _repository.deleteEvent(eventId);
}
