import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/features/subscriptions/domain/entities/subscription_info.dart';
import 'package:spotted/features/subscriptions/presentation/providers/subscriptions_providers.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeSubscriptionsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeSubscriptionsRepository(
      channels: [makeChannel(1)],
      counts: {'c1': 5},
    );
    container = ProviderContainer(
      retry: noRetry,
      overrides: [
        subscriptionsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(channelSubscriptionProvider('c1'), (_, _) {});
  });

  SubscriptionInfo? current() =>
      container.read(channelSubscriptionProvider('c1')).value;

  test('carica conteggio e stato', () async {
    final info = await container.read(channelSubscriptionProvider('c1').future);

    expect(
      info,
      const SubscriptionInfo(subscriberCount: 5, isSubscribed: false),
    );
  });

  test('toggle aggiorna subito lo stato, prima della risposta', () async {
    await container.read(channelSubscriptionProvider('c1').future);
    repository.gate = Completer<void>();

    final pending = container
        .read(channelSubscriptionProvider('c1').notifier)
        .toggle();
    await Future<void>.delayed(Duration.zero);

    // Il server non ha ancora risposto, ma la UI è già aggiornata.
    expect(
      current(),
      const SubscriptionInfo(subscriberCount: 6, isSubscribed: true),
    );

    repository.gate!.complete();
    await pending;
    expect(repository.calls, ['subscribe:c1']);
    expect(current()!.isSubscribed, isTrue);
  });

  test('toggle due volte smette di seguire', () async {
    await container.read(channelSubscriptionProvider('c1').future);
    final notifier = container.read(channelSubscriptionProvider('c1').notifier);

    await notifier.toggle();
    await notifier.toggle();

    expect(repository.calls, ['subscribe:c1', 'unsubscribe:c1']);
    expect(
      current(),
      const SubscriptionInfo(subscriberCount: 5, isSubscribed: false),
    );
  });

  test('se fallisce torna allo stato precedente e rilancia', () async {
    await container.read(channelSubscriptionProvider('c1').future);
    repository.toggleError = const NetworkFailure();

    await expectLater(
      container.read(channelSubscriptionProvider('c1').notifier).toggle(),
      throwsA(isA<NetworkFailure>()),
    );

    expect(
      current(),
      const SubscriptionInfo(subscriberCount: 5, isSubscribed: false),
    );
  });

  test(
    'un secondo tocco mentre la richiesta è in corso viene ignorato',
    () async {
      await container.read(channelSubscriptionProvider('c1').future);
      repository.gate = Completer<void>();
      final notifier = container.read(
        channelSubscriptionProvider('c1').notifier,
      );

      final first = notifier.toggle();
      await Future<void>.delayed(Duration.zero);
      await notifier.toggle();
      repository.gate!.complete();
      await first;

      expect(repository.calls, ['subscribe:c1']);
    },
  );

  test('dopo l iscrizione la lista dei canali seguiti si aggiorna', () async {
    container.listen(mySubscribedChannelsProvider, (_, _) {});
    expect(await container.read(mySubscribedChannelsProvider.future), isEmpty);
    await container.read(channelSubscriptionProvider('c1').future);

    await container.read(channelSubscriptionProvider('c1').notifier).toggle();

    final followed = await container.read(mySubscribedChannelsProvider.future);
    expect(followed.map((c) => c.id), ['c1']);
  });
}
