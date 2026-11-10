import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/features/comments/presentation/providers/comments_providers.dart';
import 'package:spotted/features/comments/presentation/providers/spot_comments_feed.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeCommentsRepository repository;
  late ProviderContainer container;
  final provider = spotCommentsFeedProvider('s1');

  setUp(() {
    repository = FakeCommentsRepository(
      comments: [
        ...List.generate(45, makeComment),
        makeComment(100, spotId: 'altro'),
      ],
    );
    container = ProviderContainer(
      retry: noRetry,
      overrides: [commentsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  List<String> ids() =>
      container.read(provider).value!.items.map((c) => c.id).toList();

  test('prima pagina da 20, solo dello spot', () async {
    final feed = await container.read(provider.future);

    expect(feed.items, hasLength(20));
    expect(feed.hasMore, isTrue);
    expect(repository.listCalls.single, (spotId: 's1', offset: 0, limit: 20));
  });

  test('loadMore accoda le pagine fino alla fine', () async {
    await container.read(provider.future);

    await container.read(provider.notifier).loadMore();
    await container.read(provider.notifier).loadMore();

    final feed = container.read(provider).value!;
    expect(feed.items, hasLength(45));
    expect(feed.hasMore, isFalse);
    expect(repository.listCalls.map((c) => c.offset), [0, 20, 40]);
  });

  test("errore in una pagina: la lista resta, c'è Riprova", () async {
    await container.read(provider.future);
    repository.listError = const NetworkFailure();

    await container.read(provider.notifier).loadMore();

    final feed = container.read(provider).value!;
    expect(feed.items, hasLength(20));
    expect(feed.loadMoreFailed, isTrue);
  });

  test('una pagina in volo non si accoda dopo una ricarica', () async {
    await container.read(provider.future);
    repository.gate = Completer<void>();

    final pending = container.read(provider.notifier).loadMore();
    container.invalidate(provider);
    await container.read(provider.future);
    repository.gate!.complete();
    await pending;

    expect(container.read(provider).value!.items, hasLength(20));
  });

  group('add', () {
    test('mette il nuovo commento in cima', () async {
      await container.read(provider.future);

      final comment = await container.read(provider.notifier).add('Ciao');

      expect(comment.content, 'Ciao');
      expect(comment.isMine, isTrue);
      expect(ids().first, comment.id);
      expect(ids(), hasLength(21));
    });

    test('testo vuoto: ValidationFailure e nessuna chiamata', () async {
      await container.read(provider.future);

      await expectLater(
        container.read(provider.notifier).add('   '),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.addCalls, isEmpty);
      expect(ids(), hasLength(20));
    });

    test('errore: rilancia e la lista non cambia', () async {
      await container.read(provider.future);
      repository.addError = const NetworkFailure();

      await expectLater(
        container.read(provider.notifier).add('Ciao'),
        throwsA(isA<NetworkFailure>()),
      );
      expect(ids(), hasLength(20));
    });
  });

  group('delete', () {
    test('toglie il commento dalla lista', () async {
      await container.read(provider.future);

      await container.read(provider.notifier).delete('k3');

      expect(repository.deleteCalls, ['k3']);
      expect(ids(), isNot(contains('k3')));
      expect(ids(), hasLength(19));
    });

    test('errore: rilancia e la lista non cambia', () async {
      await container.read(provider.future);
      repository.deleteError = const NetworkFailure();

      await expectLater(
        container.read(provider.notifier).delete('k3'),
        throwsA(isA<NetworkFailure>()),
      );
      expect(ids(), contains('k3'));
    });
  });

  group('toggleLike', () {
    test('aggiorna subito e chiama il server', () async {
      await container.read(provider.future);

      final pending = container.read(provider.notifier).toggleLike('k1');

      final during = container
          .read(provider)
          .value!
          .items
          .firstWhere((c) => c.id == 'k1');
      expect(during.likedByMe, isTrue);
      expect(during.likeCount, 1);

      await pending;
      expect(repository.likeCalls.single, (commentId: 'k1', liked: true));
    });

    test('errore: torna al valore precedente e rilancia', () async {
      await container.read(provider.future);
      repository.likeError = const NetworkFailure();

      await expectLater(
        container.read(provider.notifier).toggleLike('k1'),
        throwsA(isA<NetworkFailure>()),
      );

      final comment = container
          .read(provider)
          .value!
          .items
          .firstWhere((c) => c.id == 'k1');
      expect(comment.likedByMe, isFalse);
      expect(comment.likeCount, 0);
    });

    test(
      'un secondo tocco mentre il primo è in corso viene ignorato',
      () async {
        await container.read(provider.future);
        repository.gate = null;
        final first = container.read(provider.notifier).toggleLike('k1');
        await container.read(provider.notifier).toggleLike('k1');
        await first;

        expect(repository.likeCalls, hasLength(1));
      },
    );
  });
}
