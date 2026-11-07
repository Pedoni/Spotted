import 'package:spotted/features/subscriptions/domain/repositories/subscriptions_repository.dart';

/// Segue o smette di seguire un canale.
class SetSubscribed {
  const SetSubscribed(this._repository);

  final SubscriptionsRepository _repository;

  Future<void> call(String channelId, {required bool subscribed}) {
    return subscribed
        ? _repository.subscribe(channelId)
        : _repository.unsubscribe(channelId);
  }
}
