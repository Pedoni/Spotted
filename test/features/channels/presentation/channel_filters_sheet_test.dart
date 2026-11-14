import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channels = [
    makeChannel(
      1,
      name: 'Spotted Pisa',
      topicId: 't-uni',
      municipalityId: '050026',
      provinceCode: 'PI',
      regionName: 'Toscana',
    ),
    makeChannel(
      2,
      name: 'Spotted Pistoia',
      topicId: 't-sport',
      municipalityId: '050027',
      provinceCode: 'PT',
      regionName: 'Toscana',
    ),
    makeChannel(
      3,
      name: 'Spotted Piacenza',
      topicId: 't-uni',
      municipalityId: '033032',
      provinceCode: 'PC',
      regionName: 'Emilia-Romagna',
    ),
    makeChannel(4, name: 'Spotted Online'),
  ];

  late FakeChannelsRepository repo;

  Future<void> openSheet(WidgetTester tester) async {
    repo = FakeChannelsRepository(channels: channels);
    await pumpApp(tester, channels: repo, screenSize: const Size(800, 1400));
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filtri'));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String field, String option) async {
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String?>, field),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Applica'));
    await tester.pumpAndSettle();
  }

  Finder dropdown(String label) =>
      find.widgetWithText(DropdownButtonFormField<String?>, label);

  String? shown(WidgetTester tester, String label) {
    final field = tester.widget<DropdownButtonFormField<String?>>(
      dropdown(label),
    );
    return field.initialValue;
  }

  testWidgets('il pulsante è nella ricerca e il foglio ha tutti i filtri', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Argomento'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Sport'), findsOneWidget);
    expect(dropdown('Regione'), findsOneWidget);
    expect(dropdown('Provincia'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Comune'), findsOneWidget);
    // Niente più chip nella pagina, solo nel foglio.
    expect(find.widgetWithText(ChoiceChip, 'Sport'), findsOneWidget);
  });

  testWidgets('senza filtri il pulsante non ha il numero', (tester) async {
    await openSheet(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Azzera'));
    await apply(tester);

    expect(find.byType(Badge), findsOneWidget);
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
  });

  testWidgets('filtrare per argomento: solo i canali di quell argomento', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Sport'));
    await tester.pumpAndSettle();
    await apply(tester);

    expect(find.text('Spotted Pistoia'), findsOneWidget);
    expect(find.text('Spotted Pisa'), findsNothing);
    expect(repo.listCalls.last.topicId, 't-sport');
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('filtrare per regione', (tester) async {
    await openSheet(tester);

    await pick(tester, 'Regione', 'Emilia-Romagna');
    await apply(tester);

    expect(find.text('Spotted Piacenza'), findsOneWidget);
    expect(find.text('Spotted Pisa'), findsNothing);
    expect(repo.listCalls.last.regionName, 'Emilia-Romagna');
  });

  testWidgets('con una regione le province sono solo le sue', (tester) async {
    await openSheet(tester);
    await pick(tester, 'Regione', 'Toscana');

    await tester.tap(dropdown('Provincia'));
    await tester.pumpAndSettle();

    expect(find.text('Pisa (PI)'), findsWidgets);
    expect(find.text('Pistoia (PT)'), findsWidgets);
    expect(find.text('Piacenza (PC)'), findsNothing);
  });

  testWidgets('scegliere una provincia imposta anche la regione', (
    tester,
  ) async {
    await openSheet(tester);

    await pick(tester, 'Provincia', 'Piacenza (PC)');

    expect(shown(tester, 'Regione'), 'Emilia-Romagna');
    await apply(tester);

    expect(find.text('Spotted Piacenza'), findsOneWidget);
    expect(repo.listCalls.last.provinceCode, 'PC');
    expect(repo.listCalls.last.regionName, 'Emilia-Romagna');
  });

  testWidgets('scegliere un comune imposta provincia e regione', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Comune'), 'pis');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pisa').last);
    await tester.pumpAndSettle();

    expect(shown(tester, 'Regione'), 'Toscana');
    expect(shown(tester, 'Provincia'), 'PI');
    await apply(tester);

    expect(find.text('Spotted Pisa'), findsOneWidget);
    expect(find.text('Spotted Pistoia'), findsNothing);
    expect(repo.listCalls.last.municipalityId, '050026');
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('cambiando regione provincia e comune si azzerano', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Comune'), 'pis');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pisa').last);
    await tester.pumpAndSettle();

    await pick(tester, 'Regione', 'Emilia-Romagna');

    expect(shown(tester, 'Provincia'), isNull);
    expect(find.widgetWithText(TextField, 'Pisa (PI)'), findsNothing);
    await apply(tester);
    expect(repo.listCalls.last.provinceCode, isNull);
    expect(repo.listCalls.last.municipalityId, isNull);
    expect(repo.listCalls.last.regionName, 'Emilia-Romagna');
  });

  testWidgets('riaprendo il foglio ci sono i filtri di prima', (tester) async {
    await openSheet(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sport'));
    await pick(tester, 'Regione', 'Toscana');
    await apply(tester);

    await tester.tap(find.byTooltip('Filtri'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Sport'))
          .selected,
      isTrue,
    );
    expect(shown(tester, 'Regione'), 'Toscana');
  });

  testWidgets('Azzera toglie tutti i filtri', (tester) async {
    await openSheet(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sport'));
    await pick(tester, 'Regione', 'Toscana');
    await apply(tester);
    expect(find.text('Spotted Pistoia'), findsOneWidget);

    await tester.tap(find.byTooltip('Filtri'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Azzera'));
    await tester.pumpAndSettle();
    await apply(tester);

    expect(find.text('Spotted Pisa'), findsOneWidget);
    expect(find.text('Spotted Online'), findsOneWidget);
    expect(repo.listCalls.last.topicId, isNull);
    expect(repo.listCalls.last.regionName, isNull);
  });

  testWidgets('chiudere il foglio senza applicare non cambia niente', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sport'));
    await tester.pumpAndSettle();
    final calls = repo.listCalls.length;

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Argomento'), findsNothing);
    expect(repo.listCalls, hasLength(calls));
    expect(find.text('Spotted Pisa'), findsOneWidget);
  });

  testWidgets('i filtri si sommano al testo cercato', (tester) async {
    await openSheet(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Università'));
    await tester.pumpAndSettle();
    await apply(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Cerca un canale'),
      'piac',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Spotted Piacenza'), findsOneWidget);
    expect(find.text('Spotted Pisa'), findsNothing);
    expect(repo.listCalls.last.query, 'piac');
    expect(repo.listCalls.last.topicId, 't-uni');
  });
}
