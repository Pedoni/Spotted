import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/domain/event_validators.dart';
import 'package:spotted/features/events/domain/repositories/events_repository.dart';

class CreateEvent {
  const CreateEvent(this._repository);

  final EventsRepository _repository;

  /// Valida i campi (togliendo gli spazi ai bordi) e pubblica. Il luogo vuoto
  /// diventa "nessun luogo".
  Future<ChannelEvent> call({
    required String channelId,
    required String title,
    required String description,
    required DateTime startsAt,
    String? location,
    DateTime? endsAt,
  }) async {
    final place = location?.trim();
    if (!EventValidators.isValidTitle(title) ||
        !EventValidators.isValidDescription(description) ||
        !EventValidators.isValidLocation(place ?? '') ||
        !EventValidators.areValidDates(startsAt, endsAt)) {
      throw const ValidationFailure();
    }
    return _repository.createEvent(
      channelId: channelId,
      title: title.trim(),
      description: description.trim(),
      location: place == null || place.isEmpty ? null : place,
      startsAt: startsAt,
      endsAt: endsAt,
    );
  }
}
