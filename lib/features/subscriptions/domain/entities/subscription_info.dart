import 'package:equatable/equatable.dart';

/// Iscrizioni a un canale: quante sono e se l'utente corrente è tra queste.
class SubscriptionInfo extends Equatable {
  const SubscriptionInfo({
    required this.subscriberCount,
    required this.isSubscribed,
  });

  final int subscriberCount;
  final bool isSubscribed;

  /// Stato dopo che l'utente segue (o smette di seguire) il canale.
  SubscriptionInfo toggled() {
    return SubscriptionInfo(
      subscriberCount: isSubscribed
          ? (subscriberCount - 1).clamp(0, subscriberCount)
          : subscriberCount + 1,
      isSubscribed: !isSubscribed,
    );
  }

  @override
  List<Object?> get props => [subscriberCount, isSubscribed];
}
