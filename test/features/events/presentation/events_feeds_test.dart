import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/features/events/domain/entities/events_when.dart';
import 'package:spotted/features/events/presentation/providers/channel_events_feed.dart';
import 'package:spotted/features/events/presentation/providers/events_providers.dart';
import 'package:spotted/features/events/presentation/providers/followed_events_feed.dart';

import '../../../helpers/fake_events.dart';

void main() {
  late FakeEventsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeEventsRepository()
      ..followed = List.generate(25, (i) => makeEvent(i + 1));
    container = ProviderContainer(
      retry: noRetry,
      overrides: [eventsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('FollowedEventsFeed', () {
    test('carica a pagine di 20', () async {
      final feed = await container.read(followedEventsFeedProvider.future);
      expect(feed.items, hasLength(20));
      expect(feed.hasMore, isTrue);

      await container.read(followedEventsFeedProvider.notifier).loadMore();

      final all = container.read(followedEventsFeedProvider).value!;
      expect(all.items, hasLength(25));
      expect(all.hasMore, isFalse);
      expect(repository.followedCalls.map((c) => c.offset), [0, 20]);
    });

    test('non carica oltre l ultima pagina', () async {
      repository.followed = repository.followed.take(3).toList();
      await container.read(followedEventsFeedProvider.future);

      await container.read(followedEventsFeedProvider.notifier).loadMore();

      expect(repository.followedCalls, hasLength(1));
    });

    test('se una pagina fallisce smette di caricare e lo segnala', () async {
      await container.read(followedEventsFeedProvider.future);
      repository.followedError = const NetworkFailure();

      await container.read(followedEventsFeedProvider.notifier).loadMore();

      final state = container.read(followedEventsFeedProvider).value!;
      expect(state.loadMoreFailed, isTrue);
      expect(state.items, hasLength(20));
    });

    test('una risposta in ritardo dopo la ricarica non si accoda', () async {
      await container.read(followedEventsFeedProvider.future);
      repository.followedGate = Completer<void>();
      final late = container
          .read(followedEventsFeedProvider.notifier)
          .loadMore();

      container.invalidate(followedEventsFeedProvider);
      final reloaded = await container.read(followedEventsFeedProvider.future);
      repository.followedGate!.complete();
      await late;

      expect(reloaded.items, hasLength(20));
      expect(
        container.read(followedEventsFeedProvider).value!.items,
        hasLength(20),
      );
    });

    test('errore alla prima pagina: lo stato è un errore', () async {
      repository.followedError = const NetworkFailure();

      await expectLater(
        container.read(followedEventsFeedProvider.future),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('ChannelEventsFeed', () {
    test('un canale non vede gli eventi di un altro', () async {
      repository.events = [
        makeEvent(1),
        makeEvent(2, channelId: 'c2', channelSlug: 'canale-2'),
      ];

      final feed = await container.read(
        channelEventsFeedProvider('c1', EventsWhen.upcoming).future,
      );

      expect(feed.items.map((e) => e.id), ['e1']);
    });

    test('prossimi e passati sono due elenchi separati', () async {
      repository.events = [makeEvent(1), makeEvent(2, past: true)];

      final upcoming = await container.read(
        channelEventsFeedProvider('c1', EventsWhen.upcoming).future,
      );
      final past = await container.read(
        channelEventsFeedProvider('c1', EventsWhen.past).future,
      );

      expect(upcoming.items.map((e) => e.id), ['e1']);
      expect(past.items.map((e) => e.id), ['e2']);
    });

    test('carica a pagine di 20', () async {
      repository.events = List.generate(25, (i) => makeEvent(i + 1));
      final provider = channelEventsFeedProvider('c1', EventsWhen.upcoming);
      await container.read(provider.future);

      await container.read(provider.notifier).loadMore();

      expect(container.read(provider).value!.items, hasLength(25));
      expect(repository.listCalls.map((c) => c.offset), [0, 20]);
    });
  });
}
