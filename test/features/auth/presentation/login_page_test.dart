import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('mostra gli errori di validazione e non chiama il repository', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await pumpApp(tester, auth: repo);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text("Inserisci un'email valida"), findsOneWidget);
    expect(find.text('Campo obbligatorio'), findsOneWidget);
    expect(repo.signInCalls, isEmpty);
  });

  testWidgets('login riuscito porta alla home', (tester) async {
    final repo = FakeAuthRepository();
    await pumpApp(tester, auth: repo);

    await tester.enterText(field('Email'), 'a@b.it');
    await tester.enterText(field('Password'), 'secret123');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(repo.signInCalls.single.email, 'a@b.it');
    expect(
      find.text('Non segui ancora nessun canale'),
      findsOneWidget,
    );
  });

  testWidgets('credenziali errate mostrano il messaggio', (tester) async {
    final repo = FakeAuthRepository()
      ..signInError = const AuthFailure(AuthFailureReason.invalidCredentials);
    await pumpApp(tester, auth: repo);

    await tester.enterText(field('Email'), 'a@b.it');
    await tester.enterText(field('Password'), 'sbagliata');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Email o password non corretti'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('il link porta alla registrazione', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());

    await tester.tap(find.text('Non hai un account? Registrati'));
    await tester.pumpAndSettle();

    expect(find.text('Crea account'), findsOneWidget);
  });
}
