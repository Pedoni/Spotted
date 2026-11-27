import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/features/tags/presentation/providers/tags_providers.dart';
import 'package:spotted/features/tags/presentation/widgets/spot_tag_chips.dart';
import 'package:spotted/l10n/app_localizations.dart';

import '../../../helpers/fake_tags.dart';

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester,
    FakeTagsRepository repository,
    List<String> tags,
  ) async {
    final container = ProviderContainer(
      retry: noRetry,
      overrides: [tagsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SpotTagChips(tags: tags)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('mostra il nome visibile di ogni tag', (tester) async {
    await pump(tester, FakeTagsRepository(), ['curiosita', 'crush']);

    expect(find.text('Curiosità'), findsOneWidget);
    expect(find.text('Crush'), findsOneWidget);
    expect(find.text('curiosita'), findsNothing);
  });

  testWidgets('senza tag non occupa spazio e non scarica niente', (
    tester,
  ) async {
    final repository = FakeTagsRepository();
    await pump(tester, repository, []);

    expect(tester.getSize(find.byType(SpotTagChips)), Size.zero);
    expect(repository.allCalls, 0);
  });

  testWidgets('un tag sconosciuto si mostra col nome tecnico', (tester) async {
    await pump(tester, FakeTagsRepository(), ['nuovotag']);

    expect(find.text('nuovotag'), findsOneWidget);
  });

  testWidgets('se i nomi non arrivano si mostrano i nomi tecnici', (
    tester,
  ) async {
    final repository = FakeTagsRepository()..error = const NetworkFailure();
    await pump(tester, repository, ['curiosita']);

    expect(find.text('curiosita'), findsOneWidget);
  });

  testWidgets('i nomi si scaricano una volta sola per tutte le card', (
    tester,
  ) async {
    final repository = FakeTagsRepository();
    final container = await pump(tester, repository, ['crush']);

    // Una seconda lettura non richiede niente.
    await container.read(tagLabelsProvider.future);

    expect(repository.allCalls, 1);
  });

  test('un errore non resta in memoria: la volta dopo si riprova', () async {
    final repository = FakeTagsRepository()..error = const NetworkFailure();
    final container = ProviderContainer(
      retry: noRetry,
      overrides: [tagsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(tagLabelsProvider, (_, _) {});
    await expectLater(
      container.read(tagLabelsProvider.future),
      throwsA(isA<NetworkFailure>()),
    );

    // Chi ascoltava se ne va (si esce dalla pagina) e poi si torna.
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    repository.error = null;
    final labels = await container.read(tagLabelsProvider.future);

    expect(labels['curiosita'], 'Curiosità');
    expect(repository.allCalls, 2);
  });
}
