import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';
import 'package:spotted/features/spots/presentation/providers/spot_interaction.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeSpotsRepository repository;
  late ProviderContainer container;
  final spot = makeSpot(
    1,
    stats: const SpotStats(likeCount: 3, commentCount: 2),
  );

  setUp(() {
    repository = FakeSpotsRepository();
    container = ProviderContainer(
      retry: noRetry,
      overrides: [
        spotsRepositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: loggedInUser),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  SpotStats shown() => SpotInteraction.effective(
    spot,
    container.read(spotInteractionProvider(spot.id)),
  );

  test('senza modifiche si vedono i conteggi dello spot', () {
    expect(shown(), spot.stats);
  });

  test('toggleLike aggiorna subito e chiama il server', () async {
    final pending = container
        .read(spotInteractionProvider(spot.id).notifier)
        .toggleLike(spot);

    // Subito, prima che il server risponda.
    expect(shown().likedByMe, isTrue);
    expect(shown().likeCount, 4);

    await pending;
    expect(repository.likeCalls.single, (spotId: 's1', liked: true));
  });

  test('toggleLike due volte toglie il like', () async {
    final notifier = container.read(spotInteractionProvider(spot.id).notifier);

    await notifier.toggleLike(spot);
    await notifier.toggleLike(spot);

    expect(shown(), spot.stats);
    expect(repository.likeCalls.map((c) => c.liked), [true, false]);
  });

  test('se il server rifiuta torna ai valori precedenti', () async {
    repository.likeError = const NetworkFailure();

    await expectLater(
      container
          .read(spotInteractionProvider(spot.id).notifier)
          .toggleLike(spot),
      throwsA(isA<NetworkFailure>()),
    );

    expect(shown(), spot.stats);
  });

  test('un secondo tocco mentre il primo è in corso viene ignorato', () async {
    repository.gate = Completer<void>();
    final notifier = container.read(spotInteractionProvider(spot.id).notifier);

    final first = notifier.toggleLike(spot);
    await notifier.toggleLike(spot);
    repository.gate!.complete();
    await first;

    expect(repository.likeCalls, hasLength(1));
  });

  test(
    'se lo spot viene ricaricato con altri conteggi vince il server',
    () async {
      await container
          .read(spotInteractionProvider(spot.id).notifier)
          .toggleLike(spot);

      final reloaded = makeSpot(
        1,
        stats: const SpotStats(likeCount: 9, commentCount: 2, likedByMe: true),
      );

      expect(
        SpotInteraction.effective(
          reloaded,
          container.read(spotInteractionProvider(spot.id)),
        ),
        reloaded.stats,
      );
    },
  );

  test('addComments cambia il numero di commenti', () {
    container
        .read(spotInteractionProvider(spot.id).notifier)
        .addComments(spot, 1);
    expect(shown().commentCount, 3);

    container
        .read(spotInteractionProvider(spot.id).notifier)
        .addComments(spot, -1);
    expect(shown().commentCount, 2);
  });
}
