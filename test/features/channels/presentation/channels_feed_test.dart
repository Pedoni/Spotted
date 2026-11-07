import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/features/channels/presentation/providers/channels_feed.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeChannelsRepository repository;
  late ProviderContainer container;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      retry: noRetry,
      overrides: [channelsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    repository = FakeChannelsRepository(
      channels: List.generate(
        45,
        (i) => makeChannel(i, topicId: i.isEven ? 't-uni' : 't-sport'),
      ),
    );
    container = makeContainer();
  });

  test('prima pagina da 20 con altre disponibili', () async {
    final feed = await container.read(channelsFeedProvider.future);

    expect(feed.items, hasLength(20));
    expect(feed.hasMore, isTrue);
    expect(repository.listCalls.single.offset, 0);
  });

  test('loadMore accoda le pagine fino alla fine', () async {
    await container.read(channelsFeedProvider.future);
    final notifier = container.read(channelsFeedProvider.notifier);

    await notifier.loadMore();
    expect(container.read(channelsFeedProvider).value!.items, hasLength(40));

    await notifier.loadMore();
    final feed = container.read(channelsFeedProvider).value!;
    expect(feed.items, hasLength(45));
    expect(feed.hasMore, isFalse);
    expect(repository.listCalls.map((c) => c.offset), [0, 20, 40]);

    // Finita la lista non fa altre richieste.
    await notifier.loadMore();
    expect(repository.listCalls, hasLength(3));
  });

  test('cambiare i filtri ricarica da capo', () async {
    await container.read(channelsFeedProvider.future);

    container.read(channelFilterProvider.notifier)
      ..setQuery('Canale 4')
      ..setTopic('t-uni');
    final feed = await container.read(channelsFeedProvider.future);

    expect(feed.items.map((c) => c.name), [
      'Canale 4',
      'Canale 40',
      'Canale 42',
      'Canale 44',
    ]);
    expect(repository.listCalls.last.query, 'Canale 4');
    expect(repository.listCalls.last.topicId, 't-uni');
    expect(repository.listCalls.last.offset, 0);
  });

  test('errore nel caricamento della prima pagina', () async {
    repository.listError = const NetworkFailure();
    // Il provider è autoDispose: serve un ascoltatore finché carica.
    container.listen(channelsFeedProvider, (_, _) {});

    await expectLater(
      container.read(channelsFeedProvider.future),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('errore su loadMore: tiene la lista e permette di riprovare', () async {
    await container.read(channelsFeedProvider.future);
    final notifier = container.read(channelsFeedProvider.notifier);
    repository.listError = const NetworkFailure();

    await notifier.loadMore();

    var feed = container.read(channelsFeedProvider).value!;
    expect(feed.items, hasLength(20));
    expect(feed.hasMore, isTrue);
    expect(feed.loadMoreFailed, isTrue);
    expect(feed.isLoadingMore, isFalse);

    repository.listError = null;
    await notifier.loadMore();

    feed = container.read(channelsFeedProvider).value!;
    expect(feed.items, hasLength(40));
    expect(feed.loadMoreFailed, isFalse);
  });

  test(
    'loadMore ancora in volo dopo un cambio filtro non sporca la lista',
    () async {
      final slow = SlowPagesChannelsRepository(channels: repository.channels);
      final c = ProviderContainer(
        retry: noRetry,
        overrides: [channelsRepositoryProvider.overrideWithValue(slow)],
      );
      addTearDown(c.dispose);
      c.listen(channelsFeedProvider, (_, _) {});
      await c.read(channelsFeedProvider.future);

      slow.gate = Completer<void>();
      final loading = c.read(channelsFeedProvider.notifier).loadMore();
      await Future<void>.delayed(Duration.zero);

      // Mentre la pagina 2 è in volo l'utente cambia filtro: la lista riparte.
      c.read(channelFilterProvider.notifier).setTopic('t-sport');
      await c.read(channelsFeedProvider.future);
      slow.gate!.complete();
      await loading;

      final items = c.read(channelsFeedProvider).value!.items;
      expect(items.every((channel) => channel.topicId == 't-sport'), isTrue);
      expect(items, hasLength(20));
    },
  );
}
