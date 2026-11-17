import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/domain/repositories/events_repository.dart';

class GetFollowedEvents {
  const GetFollowedEvents(this._repository);

  final EventsRepository _repository;

  Future<List<ChannelEvent>> call({required int offset, required int limit}) {
    return _repository.getFollowedEvents(offset: offset, limit: limit);
  }
}
