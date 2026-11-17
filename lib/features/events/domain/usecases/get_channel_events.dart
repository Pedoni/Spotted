import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/domain/entities/events_when.dart';
import 'package:spotted/features/events/domain/repositories/events_repository.dart';

class GetChannelEvents {
  const GetChannelEvents(this._repository);

  final EventsRepository _repository;

  Future<List<ChannelEvent>> call({
    required String channelId,
    required EventsWhen when,
    required int offset,
    required int limit,
  }) {
    return _repository.getChannelEvents(
      channelId: channelId,
      when: when,
      offset: offset,
      limit: limit,
    );
  }
}
