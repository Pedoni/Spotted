import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> openSignUp(WidgetTester tester, FakeAuthRepository repo) async {
    await pumpApp(tester, auth: repo);
    await tester.tap(find.text('Non hai un account? Registrati'));
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String username = 'Mario_88',
  }) async {
    await tester.enterText(field('Nome'), 'Mario');
    await tester.enterText(field('Cognome'), 'Rossi');
    await tester.enterText(field('Username'), username);
    await tester.enterText(field('Email'), 'mario@b.it');
    await tester.enterText(field('Password'), '12345678');
  }

  testWidgets('valida i campi', (tester) async {
    final repo = FakeAuthRepository();
    await openSignUp(tester, repo);

    await tester.enterText(field('Username'), 'a!');
    await tester.enterText(field('Password'), 'corta');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Campo obbligatorio'), findsNWidgets(2));
    expect(
      find.text('3-30 caratteri: lettere, numeri e underscore'),
      findsOneWidget,
    );
    expect(find.text('Almeno 8 caratteri'), findsOneWidget);
    expect(repo.signUpCalls, isEmpty);
  });

  testWidgets('registrazione riuscita: username normalizzato e home', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await openSignUp(tester, repo);

    await fillForm(tester);
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(repo.signUpCalls.single['username'], 'mario_88');
    expect(repo.signUpCalls.single['firstName'], 'Mario');
    expect(
      find.text('Ancora nessuno spot da mostrare'),
      findsOneWidget,
    );
  });

  testWidgets('username occupato mostra l errore', (tester) async {
    final repo = FakeAuthRepository()..takenUsernames = {'mario_88'};
    await openSignUp(tester, repo);

    await fillForm(tester);
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Questo username è già in uso'), findsOneWidget);
    expect(repo.signUpCalls, isEmpty);
  });
}
