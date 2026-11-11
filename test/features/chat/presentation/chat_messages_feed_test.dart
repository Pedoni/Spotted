import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/features/chat/presentation/providers/chat_messages_feed.dart';
import 'package:spotted/features/chat/presentation/providers/chat_providers.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeChatRepository repository;
  late ProviderContainer container;
  final provider = chatMessagesFeedProvider('ch1');

  setUp(() {
    repository = FakeChatRepository(
      messages: {
        'ch1': List.generate(45, makeMessage),
        'altra': [makeMessage(100)],
      },
    );
    container = ProviderContainer(
      retry: noRetry,
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
        chatPollIntervalProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
  });

  List<String> ids() =>
      container.read(provider).value!.items.map((m) => m.id).toList();

  test('prima pagina da 20, solo della chat', () async {
    final feed = await container.read(provider.future);

    expect(feed.items, hasLength(20));
    expect(feed.hasMore, isTrue);
    expect(repository.messageCalls.single, (
      chatId: 'ch1',
      offset: 0,
      limit: 20,
    ));
  });

  test('loadMore accoda le pagine fino alla fine', () async {
    await container.read(provider.future);

    await container.read(provider.notifier).loadMore();
    await container.read(provider.notifier).loadMore();

    final feed = container.read(provider).value!;
    expect(feed.items, hasLength(45));
    expect(feed.hasMore, isFalse);
    expect(repository.messageCalls.map((c) => c.offset), [0, 20, 40]);
  });

  test("errore in una pagina: la lista resta, c'è Riprova", () async {
    await container.read(provider.future);
    repository.messagesError = const NetworkFailure();

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

  group('send', () {
    test('mette il messaggio in cima', () async {
      await container.read(provider.future);

      final message = await container.read(provider.notifier).send('Ciao');

      expect(message.isMine, isTrue);
      expect(ids().first, message.id);
      expect(container.read(provider).value!.items, hasLength(21));
      expect(repository.sendCalls.single, (chatId: 'ch1', content: 'Ciao'));
    });

    test('se fallisce rilancia e la lista non cambia', () async {
      await container.read(provider.future);
      repository.sendError = const NetworkFailure();

      await expectLater(
        container.read(provider.notifier).send('Ciao'),
        throwsA(isA<NetworkFailure>()),
      );

      expect(container.read(provider).value!.items, hasLength(20));
    });

    test('testo vuoto: ValidationFailure, nessuna richiesta', () async {
      await container.read(provider.future);

      await expectLater(
        container.read(provider.notifier).send('   '),
        throwsA(isA<ValidationFailure>()),
      );

      expect(repository.sendCalls, isEmpty);
    });
  });

  group('refreshNewest', () {
    test('aggiunge in cima i messaggi arrivati', () async {
      await container.read(provider.future);
      repository.messages['ch1'] = [
        makeMessage(-2, content: 'Nuovo 2'),
        makeMessage(-1, content: 'Nuovo 1'),
        ...repository.messages['ch1']!,
      ];

      await container.read(provider.notifier).refreshNewest();

      expect(ids().take(3), ['m-2', 'm-1', 'm0']);
      expect(container.read(provider).value!.items, hasLength(22));
    });

    test('un messaggio già presente non si duplica', () async {
      await container.read(provider.future);
      final sent = await container.read(provider.notifier).send('Ciao');

      // Il controllo lo trova anche sul server.
      await container.read(provider.notifier).refreshNewest();

      expect(ids().where((id) => id == sent.id), hasLength(1));
      expect(container.read(provider).value!.items, hasLength(21));
    });

    test('un errore non cambia la lista né la segna in errore', () async {
      await container.read(provider.future);
      repository.messagesError = const NetworkFailure();

      await container.read(provider.notifier).refreshNewest();

      final state = container.read(provider);
      expect(state.hasError, isFalse);
      expect(state.value!.items, hasLength(20));
      expect(state.value!.loadMoreFailed, isFalse);
    });

    test('non cambia la paginazione dei messaggi più vecchi', () async {
      await container.read(provider.future);
      await container.read(provider.notifier).refreshNewest();

      await container.read(provider.notifier).loadMore();

      expect(container.read(provider).value!.items, hasLength(40));
    });
  });
}
