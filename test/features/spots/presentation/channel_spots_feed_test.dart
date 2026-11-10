import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/features/spots/presentation/providers/channel_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeSpotsRepository repository;
  late ProviderContainer container;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      retry: noRetry,
      overrides: [spotsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('ChannelSpotsFeed', () {
    setUp(() {
      repository = FakeSpotsRepository(
        spots: [
          ...List.generate(45, makeSpot),
          makeSpot(100, channelId: 'altro'),
        ],
      );
      container = makeContainer();
    });

    test('prima pagina da 20 con altre disponibili, solo del canale', () async {
      final feed = await container.read(channelSpotsFeedProvider('c1').future);

      expect(feed.items, hasLength(20));
      expect(feed.hasMore, isTrue);
      expect(repository.listCalls.single.channelId, 'c1');
      expect(repository.listCalls.single.offset, 0);
    });

    test('loadMore accoda le pagine fino alla fine', () async {
      final provider = channelSpotsFeedProvider('c1');
      await container.read(provider.future);

      await container.read(provider.notifier).loadMore();
      expect(container.read(provider).value!.items, hasLength(40));

      await container.read(provider.notifier).loadMore();
      final feed = container.read(provider).value!;
      expect(feed.items, hasLength(45));
      expect(feed.hasMore, isFalse);
      expect(repository.listCalls.map((c) => c.offset), [0, 20, 40]);

      // Finita la lista non fa altre richieste.
      await container.read(provider.notifier).loadMore();
      expect(repository.listCalls, hasLength(3));
    });

    test('ogni canale ha la sua lista', () async {
      final other = await container.read(
        channelSpotsFeedProvider('altro').future,
      );

      expect(other.items.single.id, 's100');
    });

    test(
      "errore nel caricare una pagina: la lista resta, c'è Riprova",
      () async {
        final provider = channelSpotsFeedProvider('c1');
        await container.read(provider.future);
        repository.listError = const NetworkFailure();

        await container.read(provider.notifier).loadMore();

        final feed = container.read(provider).value!;
        expect(feed.items, hasLength(20));
        expect(feed.loadMoreFailed, isTrue);
        expect(feed.isLoadingMore, isFalse);

        repository.listError = null;
        await container.read(provider.notifier).loadMore();
        expect(container.read(provider).value!.items, hasLength(40));
      },
    );

    test('errore alla prima pagina: stato di errore', () async {
      repository.listError = const NetworkFailure();

      await expectLater(
        container.read(channelSpotsFeedProvider('c1').future),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('una pagina in volo non si accoda dopo una ricarica', () async {
      final provider = channelSpotsFeedProvider('c1');
      await container.read(provider.future);
      repository.gate = Completer<void>();

      final pending = container.read(provider.notifier).loadMore();
      container.invalidate(provider);
      final reloaded = await container.read(provider.future);
      repository.gate!.complete();
      await pending;

      expect(reloaded.items, hasLength(20));
      expect(container.read(provider).value!.items, hasLength(20));
    });
  });
}
