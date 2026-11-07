import 'package:spotted/features/subscriptions/domain/entities/subscription_info.dart';
import 'package:spotted/features/subscriptions/domain/repositories/subscriptions_repository.dart';

class GetSubscriptionInfo {
  const GetSubscriptionInfo(this._repository);

  final SubscriptionsRepository _repository;

  Future<SubscriptionInfo> call(String channelId) =>
      _repository.getInfo(channelId);
}
