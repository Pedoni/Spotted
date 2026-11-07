import 'package:spotted/features/channels/data/models/channel_dto.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/subscriptions/data/models/subscription_info_dto.dart';
import 'package:spotted/features/subscriptions/domain/entities/subscription_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le iscrizioni passano solo dalle funzioni del database: la tabella
/// `subscriptions` non è accessibile ai client.
class SubscriptionsRemoteDataSource {
  const SubscriptionsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<SubscriptionInfo> getInfo(String channelId) async {
    final rows = await _client.rpc<List<dynamic>>(
      'channel_subscription_info',
      params: {'p_channel_id': channelId},
    );
    final row = rows.single as Map<String, dynamic>;
    return SubscriptionInfoDto.fromJson(row).toEntity();
  }

  Future<void> subscribe(String channelId) {
    return _client.rpc<void>(
      'subscribe_to_channel',
      params: {'p_channel_id': channelId},
    );
  }

  Future<void> unsubscribe(String channelId) {
    return _client.rpc<void>(
      'unsubscribe_from_channel',
      params: {'p_channel_id': channelId},
    );
  }

  Future<List<Channel>> getMySubscribedChannels() async {
    final rows = await _client.rpc<List<dynamic>>('my_subscribed_channels');
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => ChannelDto.fromJson(row).toEntity())
        .toList();
  }
}
