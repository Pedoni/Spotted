import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/features/spots/presentation/providers/channel_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/my_spots_feed.dart';
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

  group('MySpotsFeed', () {
    setUp(() {
      repository = FakeSpotsRepository(mine: List.generate(25, makeMySpot));
      container = makeContainer();
    });

    test('carica a pagine', () async {
      final feed = await container.read(mySpotsFeedProvider.future);
      expect(feed.items, hasLength(20));
      expect(feed.hasMore, isTrue);

      await container.read(mySpotsFeedProvider.notifier).loadMore();

      final all = container.read(mySpotsFeedProvider).value!;
      expect(all.items, hasLength(25));
      expect(all.hasMore, isFalse);
    });

    test('delete toglie lo spot dalla lista e lo cancella', () async {
      await container.read(mySpotsFeedProvider.future);

      await container.read(mySpotsFeedProvider.notifier).delete('s3');

      expect(repository.deleteCalls, ['s3']);
      final items = container.read(mySpotsFeedProvider).value!.items;
      expect(items.any((m) => m.spot.id == 's3'), isFalse);
      expect(items, hasLength(19));
    });

    test("delete fallito: la lista non cambia e l'errore sale", () async {
      await container.read(mySpotsFeedProvider.future);
      repository.deleteError = const NetworkFailure();

      await expectLater(
        container.read(mySpotsFeedProvider.notifier).delete('s3'),
        throwsA(isA<NetworkFailure>()),
      );

      expect(container.read(mySpotsFeedProvider).value!.items, hasLength(20));
    });

    test('cancellare ricarica il feed dei canali', () async {
      repository.spots = [makeSpot(3)];
      await container.read(mySpotsFeedProvider.future);
      final before = await container.read(
        channelSpotsFeedProvider('c1').future,
      );
      expect(before.items, hasLength(1));

      await container.read(mySpotsFeedProvider.notifier).delete('s3');

      final after = await container.read(channelSpotsFeedProvider('c1').future);
      expect(after.items, isEmpty);
    });
  });
}
