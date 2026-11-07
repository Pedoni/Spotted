import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/subscriptions/domain/repositories/subscriptions_repository.dart';

class GetMySubscribedChannels {
  const GetMySubscribedChannels(this._repository);

  final SubscriptionsRepository _repository;

  Future<List<Channel>> call() => _repository.getMySubscribedChannels();
}
