import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> openForm(
    WidgetTester tester,
    FakeSpotsRepository spots,
  ) async {
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots: spots,
    );
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pubblica uno spot'));
    await tester.pumpAndSettle();
  }

  testWidgets('il form avvisa che lo spot è anonimo', (tester) async {
    await openForm(tester, FakeSpotsRepository());

    expect(
      find.text(
        'Lo spot è anonimo: solo il proprietario del canale può vedere chi lo '
        'ha scritto.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('titolo e testo sono obbligatori', (tester) async {
    final spots = FakeSpotsRepository();
    await openForm(tester, spots);

    await tester.enterText(field('Titolo'), '   ');
    await tester.tap(find.text('Pubblica'));
    await tester.pump();

    expect(find.text('Campo obbligatorio'), findsNWidgets(2));
    expect(spots.createCalls, isEmpty);
  });

  testWidgets('pubblica lo spot e torna al canale con lo spot in lista', (
    tester,
  ) async {
    final spots = FakeSpotsRepository();
    await openForm(tester, spots);

    await tester.enterText(field('Titolo'), '  Ombrello perso  ');
    await tester.enterText(field('Testo'), 'Blu, lasciato in aula 5');
    await tester.tap(find.text('Pubblica'));
    await tester.pumpAndSettle();

    expect(spots.createCalls.single, {
      'channelId': 'c1',
      'title': 'Ombrello perso',
      'content': 'Blu, lasciato in aula 5',
    });
    expect(find.text('Spot pubblicato'), findsOneWidget);
    // Siamo tornati sul canale e il feed è stato ricaricato.
    expect(find.text('Pubblica'), findsNothing);
    expect(find.text('Ombrello perso'), findsOneWidget);
  });

  testWidgets('errore di rete: messaggio e resta sul form', (tester) async {
    final spots = FakeSpotsRepository()..createError = const NetworkFailure();
    await openForm(tester, spots);

    await tester.enterText(field('Titolo'), 'Titolo');
    await tester.enterText(field('Testo'), 'Testo');
    await tester.tap(find.text('Pubblica'));
    await tester.pumpAndSettle();

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
    expect(find.text('Pubblica'), findsOneWidget);
  });
}
