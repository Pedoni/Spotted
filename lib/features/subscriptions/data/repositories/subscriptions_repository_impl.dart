import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/subscriptions/data/datasources/subscriptions_remote_data_source.dart';
import 'package:spotted/features/subscriptions/domain/entities/subscription_info.dart';
import 'package:spotted/features/subscriptions/domain/repositories/subscriptions_repository.dart';

class SubscriptionsRepositoryImpl implements SubscriptionsRepository {
  const SubscriptionsRepositoryImpl(this._dataSource);

  final SubscriptionsRemoteDataSource _dataSource;

  @override
  Future<SubscriptionInfo> getInfo(String channelId) {
    return guardFailures(() => _dataSource.getInfo(channelId));
  }

  @override
  Future<void> subscribe(String channelId) {
    return guardFailures(() => _dataSource.subscribe(channelId));
  }

  @override
  Future<void> unsubscribe(String channelId) {
    return guardFailures(() => _dataSource.unsubscribe(channelId));
  }

  @override
  Future<List<Channel>> getMySubscribedChannels() {
    return guardFailures(_dataSource.getMySubscribedChannels);
  }
}
