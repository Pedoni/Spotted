import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> openForm(
    WidgetTester tester,
    FakeChannelsRepository repository,
  ) async {
    await pumpApp(tester, channels: repository);
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuovo canale'));
    await tester.pumpAndSettle();
  }

  testWidgets('valida il nome', (tester) async {
    final repo = FakeChannelsRepository();
    await openForm(tester, repo);

    await tester.enterText(field('Nome del canale'), 'ab');
    await tester.tap(find.text('Crea canale'));
    await tester.pump();

    expect(find.text('Da 3 a 60 caratteri'), findsOneWidget);
    expect(repo.createCalls, isEmpty);
  });

  testWidgets('crea il canale e apre la sua pagina', (tester) async {
    final repo = FakeChannelsRepository();
    await openForm(tester, repo);

    await tester.enterText(field('Nome del canale'), 'Spotted Università Pisa');
    await tester.enterText(field('Comune (facoltativo)'), 'pis');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pisa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Università').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crea canale'));
    await tester.pumpAndSettle();

    final call = repo.createCalls.single;
    expect(call['slug'], 'spotted-universita-pisa');
    expect(call['municipalityId'], '050026');
    expect(call['topicId'], 't-uni');
    // Ora si vede la pagina del canale, non più il form.
    expect(find.text('Crea canale'), findsNothing);
    expect(find.text('Spotted Università Pisa'), findsWidgets);
  });

  testWidgets('errore di rete mostra il messaggio e resta sul form', (
    tester,
  ) async {
    final repo = FakeChannelsRepository()..createError = const NetworkFailure();
    await openForm(tester, repo);

    await tester.enterText(field('Nome del canale'), 'Spotted Pisa');
    await tester.tap(find.text('Crea canale'));
    await tester.pumpAndSettle();

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
    expect(find.text('Crea canale'), findsOneWidget);
  });

  group('comune', () {
    Future<void> pickPisa(WidgetTester tester) async {
      await tester.enterText(field('Comune (facoltativo)'), 'pis');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pisa'));
      await tester.pumpAndSettle();
    }

    testWidgets('è facoltativo: il canale si crea anche senza', (
      tester,
    ) async {
      final repo = FakeChannelsRepository();
      await openForm(tester, repo);

      await tester.enterText(field('Nome del canale'), 'Università online');
      await tester.tap(find.text('Crea canale'));
      await tester.pumpAndSettle();

      expect(repo.createCalls.single['municipalityId'], isNull);
      expect(find.text('Crea canale'), findsNothing);
    });

    testWidgets('un comune scritto a mano e non scelto blocca l invio', (
      tester,
    ) async {
      final repo = FakeChannelsRepository();
      await openForm(tester, repo);

      await tester.enterText(field('Nome del canale'), 'Spotted Pisa');
      await tester.enterText(field('Comune (facoltativo)'), 'Cittàinventata');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Crea canale'));
      await tester.pumpAndSettle();

      expect(find.text("Scegli un comune dall'elenco"), findsOneWidget);
      expect(repo.createCalls, isEmpty);
      expect(find.text('Crea canale'), findsOneWidget);
    });

    testWidgets('il comune scelto compare nel campo e nella chiamata', (
      tester,
    ) async {
      final repo = FakeChannelsRepository();
      await openForm(tester, repo);

      await tester.enterText(field('Nome del canale'), 'Spotted Pisa');
      await pickPisa(tester);
      expect(find.text('Pisa (PI)'), findsOneWidget);
      await tester.tap(find.text('Crea canale'));
      await tester.pumpAndSettle();

      expect(repo.createCalls.single['municipalityId'], '050026');
    });

    testWidgets('togliendo il comune scelto si crea senza', (tester) async {
      final repo = FakeChannelsRepository();
      await openForm(tester, repo);

      await tester.enterText(field('Nome del canale'), 'Spotted Pisa');
      await pickPisa(tester);
      await tester.tap(find.byTooltip('Togli il comune'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crea canale'));
      await tester.pumpAndSettle();

      expect(repo.createCalls.single['municipalityId'], isNull);
    });

    testWidgets('il canale creato mostra il luogo calcolato dal comune', (
      tester,
    ) async {
      final repo = FakeChannelsRepository();
      await openForm(tester, repo);

      await tester.enterText(field('Nome del canale'), 'Spotted Pisa');
      await pickPisa(tester);
      await tester.tap(find.text('Crea canale'));
      await tester.pumpAndSettle();

      // Nella pagina del canale appena creato compare il luogo.
      expect(find.text('Pisa (PI)'), findsOneWidget);
    });
  });
}
