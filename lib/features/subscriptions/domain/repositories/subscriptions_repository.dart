import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/subscriptions/domain/entities/subscription_info.dart';

/// Contratto delle iscrizioni. Le implementazioni lanciano un `Failure`.
abstract interface class SubscriptionsRepository {
  Future<SubscriptionInfo> getInfo(String channelId);

  /// Idempotente: seguire un canale già seguito non è un errore.
  Future<void> subscribe(String channelId);

  Future<void> unsubscribe(String channelId);

  /// Canali seguiti dall'utente, dal più recente.
  Future<List<Channel>> getMySubscribedChannels();
}
