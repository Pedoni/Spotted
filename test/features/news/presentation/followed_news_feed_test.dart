import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/features/news/presentation/providers/channel_news_feed.dart';
import 'package:spotted/features/news/presentation/providers/followed_news_feed.dart';
import 'package:spotted/features/news/presentation/providers/news_providers.dart';

import '../../../helpers/fake_news.dart';

void main() {
  late FakeNewsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeNewsRepository()
      ..followed = List.generate(25, (i) => makeNews(i + 1));
    container = ProviderContainer(
      retry: noRetry,
      overrides: [newsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('FollowedNewsFeed', () {
    test('carica a pagine di 20', () async {
      final feed = await container.read(followedNewsFeedProvider.future);
      expect(feed.items, hasLength(20));
      expect(feed.hasMore, isTrue);

      await container.read(followedNewsFeedProvider.notifier).loadMore();

      final all = container.read(followedNewsFeedProvider).value!;
      expect(all.items, hasLength(25));
      expect(all.hasMore, isFalse);
      expect(repository.followedCalls.map((c) => c.offset), [0, 20]);
    });

    test('non carica oltre l ultima pagina', () async {
      repository.followed = repository.followed.take(3).toList();
      await container.read(followedNewsFeedProvider.future);

      await container.read(followedNewsFeedProvider.notifier).loadMore();

      expect(repository.followedCalls, hasLength(1));
    });

    test('se una pagina fallisce smette di caricare e lo segnala', () async {
      await container.read(followedNewsFeedProvider.future);
      repository.followedError = const NetworkFailure();

      await container.read(followedNewsFeedProvider.notifier).loadMore();

      final state = container.read(followedNewsFeedProvider).value!;
      expect(state.loadMoreFailed, isTrue);
      expect(state.items, hasLength(20));
    });

    test('una risposta in ritardo dopo la ricarica non si accoda', () async {
      await container.read(followedNewsFeedProvider.future);
      repository.followedGate = Completer<void>();
      final late = container.read(followedNewsFeedProvider.notifier).loadMore();

      container.invalidate(followedNewsFeedProvider);
      final reloaded = await container.read(followedNewsFeedProvider.future);
      repository.followedGate!.complete();
      await late;

      expect(reloaded.items, hasLength(20));
      expect(
        container.read(followedNewsFeedProvider).value!.items,
        hasLength(20),
      );
    });

    test('errore alla prima pagina: lo stato è un errore', () async {
      repository.followedError = const NetworkFailure();

      await expectLater(
        container.read(followedNewsFeedProvider.future),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('ChannelNewsFeed', () {
    test('un canale non vede le news di un altro', () async {
      repository.news = [
        makeNews(1),
        makeNews(2, channelId: 'c2', channelSlug: 'canale-2'),
      ];

      final feed = await container.read(channelNewsFeedProvider('c1').future);

      expect(feed.items.map((n) => n.id), ['n1']);
    });

    test('carica a pagine di 20', () async {
      repository.news = List.generate(25, (i) => makeNews(i + 1));
      await container.read(channelNewsFeedProvider('c1').future);

      await container.read(channelNewsFeedProvider('c1').notifier).loadMore();

      expect(
        container.read(channelNewsFeedProvider('c1')).value!.items,
        hasLength(25),
      );
      expect(repository.listCalls.map((c) => c.offset), [0, 20]);
    });
  });
}
