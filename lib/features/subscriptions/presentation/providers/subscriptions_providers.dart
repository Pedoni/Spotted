import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/spots/presentation/providers/followed_spots_feed.dart';
import 'package:spotted/features/subscriptions/data/datasources/subscriptions_remote_data_source.dart';
import 'package:spotted/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import 'package:spotted/features/subscriptions/domain/entities/subscription_info.dart';
import 'package:spotted/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:spotted/features/subscriptions/domain/usecases/get_my_subscribed_channels.dart';
import 'package:spotted/features/subscriptions/domain/usecases/get_subscription_info.dart';
import 'package:spotted/features/subscriptions/domain/usecases/set_subscribed.dart';

part 'subscriptions_providers.g.dart';

@Riverpod(keepAlive: true)
SubscriptionsRepository subscriptionsRepository(Ref ref) {
  return SubscriptionsRepositoryImpl(
    SubscriptionsRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

/// Canali seguiti dall'utente (Home).
@riverpod
Future<List<Channel>> mySubscribedChannels(Ref ref) {
  return GetMySubscribedChannels(ref.watch(subscriptionsRepositoryProvider))();
}

/// Iscritti di un canale e stato dell'utente corrente.
@riverpod
class ChannelSubscription extends _$ChannelSubscription {
  bool _busy = false;

  @override
  Future<SubscriptionInfo> build(String channelId) {
    return GetSubscriptionInfo(ref.watch(subscriptionsRepositoryProvider))(
      channelId,
    );
  }

  /// Segue o smette di seguire il canale. Aggiorna subito lo stato (così la UI
  /// risponde senza attese); se la richiesta fallisce torna allo stato
  /// precedente e rilancia l'errore.
  Future<void> toggle() async {
    final current = state.value;
    if (current == null || _busy) return;

    _busy = true;
    final next = current.toggled();
    state = AsyncData(next);
    try {
      await SetSubscribed(ref.read(subscriptionsRepositoryProvider))(
        channelId,
        subscribed: next.isSubscribed,
      );
      if (ref.mounted) {
        ref
          ..invalidate(mySubscribedChannelsProvider)
          ..invalidate(followedSpotsFeedProvider);
      }
    } on Exception {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    } finally {
      _busy = false;
    }
  }
}
