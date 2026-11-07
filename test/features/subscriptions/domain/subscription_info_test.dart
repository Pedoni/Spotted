import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/subscriptions/domain/entities/subscription_info.dart';

void main() {
  test('seguire aumenta gli iscritti e imposta isSubscribed', () {
    const info = SubscriptionInfo(subscriberCount: 3, isSubscribed: false);

    expect(
      info.toggled(),
      const SubscriptionInfo(subscriberCount: 4, isSubscribed: true),
    );
  });

  test('smettere di seguire diminuisce gli iscritti', () {
    const info = SubscriptionInfo(subscriberCount: 3, isSubscribed: true);

    expect(
      info.toggled(),
      const SubscriptionInfo(subscriberCount: 2, isSubscribed: false),
    );
  });

  test('il conteggio non scende sotto zero', () {
    const info = SubscriptionInfo(subscriberCount: 0, isSubscribed: true);

    expect(info.toggled().subscriberCount, 0);
  });

  test('toggled due volte torna allo stato iniziale', () {
    const info = SubscriptionInfo(subscriberCount: 5, isSubscribed: false);

    expect(info.toggled().toggled(), info);
  });
}
