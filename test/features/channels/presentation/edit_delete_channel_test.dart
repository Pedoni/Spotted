import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(
    1,
    name: 'Spotted Pisa',
    topicId: 't-uni',
    description: 'Gli spot di Pisa',
    municipalityId: '050026',
    place: 'Pisa (PI)',
  );

  late FakeChannelsRepository repo;

  /// Apre Canali → il canale.
  Future<void> openChannel(
    WidgetTester tester, {
    bool owner = true,
  }) async {
    repo = FakeChannelsRepository(channels: [channel], mine: [channel]);
    await pumpApp(
      tester,
      channels: repo,
      moderation: FakeModerationRepository(
        ownedChannelIds: owner ? {'c1'} : {},
      ),
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  group('menu del proprietario', () {
    testWidgets('chi non è proprietario non vede il menu', (tester) async {
      await openChannel(tester, owner: false);

      expect(find.byTooltip('Altre azioni'), findsNothing);
      expect(find.byTooltip('Moderazione'), findsNothing);
    });

    testWidgets('il proprietario può modificare ed eliminare', (tester) async {
      await openChannel(tester);

      expect(find.byTooltip('Moderazione'), findsOneWidget);
      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();

      expect(find.text('Modifica canale'), findsOneWidget);
      expect(find.text('Elimina canale'), findsOneWidget);
    });
  });

  group('modifica', () {
    testWidgets('il modulo parte dai valori del canale, senza lo slug', (
      tester,
    ) async {
      await openChannel(tester);

      await openMenu(tester, 'Modifica canale');

      expect(find.text('Modifica canale'), findsOneWidget);
      expect(field('Nome del canale'), findsOneWidget);
      expect(find.text('Spotted Pisa'), findsOneWidget);
      expect(find.text('Gli spot di Pisa'), findsOneWidget);
      expect(find.text('Pisa (PI)'), findsOneWidget);
      expect(find.text('Università'), findsOneWidget);
      expect(find.textContaining('canale-1'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Salva'), findsOneWidget);
    });

    testWidgets('salva le modifiche, torna al canale e lo slug non cambia', (
      tester,
    ) async {
      await openChannel(tester);
      await openMenu(tester, 'Modifica canale');

      await tester.enterText(field('Nome del canale'), 'Spotted Pisa Nord');
      await tester.enterText(field('Descrizione (facoltativa)'), 'Nuova');
      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();

      final call = repo.updateCalls.single;
      expect(call['channelId'], 'c1');
      expect(call['name'], 'Spotted Pisa Nord');
      expect(call['description'], 'Nuova');
      expect(call['topicId'], 't-uni');
      expect(call['municipalityId'], '050026');
      expect(find.text('Canale aggiornato'), findsOneWidget);
      // Di nuovo sul canale, con il nome nuovo.
      expect(find.text('Modifica canale'), findsNothing);
      expect(find.text('Spotted Pisa Nord'), findsWidgets);
      expect(repo.channels.single.slug, 'canale-1');
    });

    testWidgets('si può cambiare il comune e toglierlo', (tester) async {
      await openChannel(tester);
      await openMenu(tester, 'Modifica canale');

      // Toglie il comune con la "x".
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();

      expect(repo.updateCalls.single['municipalityId'], isNull);
    });

    testWidgets('un nome troppo corto non parte', (tester) async {
      await openChannel(tester);
      await openMenu(tester, 'Modifica canale');

      await tester.enterText(field('Nome del canale'), 'No');
      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();

      expect(repo.updateCalls, isEmpty);
      expect(find.text('Modifica canale'), findsOneWidget);
    });

    testWidgets('errore: messaggio, si resta sul modulo e si può riprovare', (
      tester,
    ) async {
      await openChannel(tester);
      await openMenu(tester, 'Modifica canale');
      repo.updateError = const NetworkFailure();

      await tester.enterText(field('Nome del canale'), 'Spotted Pisa Nord');
      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('Modifica canale'), findsOneWidget);

      repo.updateError = null;
      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();

      expect(find.text('Canale aggiornato'), findsOneWidget);
    });

    testWidgets('non proprietario (42501): messaggio di permesso', (
      tester,
    ) async {
      await openChannel(tester);
      await openMenu(tester, 'Modifica canale');
      repo.updateError = const PermissionFailure();

      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();

      expect(
        find.text('Non hai i permessi per eseguire questa azione'),
        findsOneWidget,
      );
    });

    testWidgets('dopo la modifica anche l elenco dei canali è aggiornato', (
      tester,
    ) async {
      await openChannel(tester);
      await openMenu(tester, 'Modifica canale');
      await tester.enterText(field('Nome del canale'), 'Spotted Pisa Nord');
      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Indietro'));
      await tester.pumpAndSettle();

      expect(find.text('Spotted Pisa Nord'), findsOneWidget);
      expect(find.text('Spotted Pisa'), findsNothing);
    });
  });

  group('eliminazione', () {
    testWidgets('chiede conferma e Annulla non elimina niente', (tester) async {
      await openChannel(tester);

      await openMenu(tester, 'Elimina canale');

      expect(find.text('Eliminare il canale?'), findsOneWidget);
      expect(find.textContaining('tutti i suoi spot'), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminare il canale?'), findsNothing);
      expect(repo.deleteCalls, isEmpty);
      expect(find.byTooltip('Altre azioni'), findsOneWidget);
    });

    testWidgets('confermando elimina il canale e torna all elenco', (
      tester,
    ) async {
      await openChannel(tester);

      await openMenu(tester, 'Elimina canale');
      await tester.tap(find.widgetWithText(TextButton, 'Elimina'));
      await tester.pumpAndSettle();

      expect(repo.deleteCalls, ['c1']);
      expect(find.text('Canale eliminato'), findsOneWidget);
      // Siamo di nuovo in Canali e il canale non c'è più.
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Spotted Pisa'), findsNothing);
    });

    testWidgets('errore: messaggio e il canale resta', (tester) async {
      await openChannel(tester);
      repo.deleteError = const NetworkFailure();

      await openMenu(tester, 'Elimina canale');
      await tester.tap(find.widgetWithText(TextButton, 'Elimina'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.byTooltip('Altre azioni'), findsOneWidget);
      expect(repo.channels, hasLength(1));
    });
  });
}
