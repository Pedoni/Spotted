import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/app.dart';
import 'package:spotted/features/auth/domain/entities/app_user.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/pump_app.dart';

void main() {
  testWidgets('senza sessione mostra il login', (tester) async {
    await pumpApp(tester, FakeAuthRepository());

    expect(find.text('Accedi'), findsWidgets);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('con sessione mostra la home', (tester) async {
    await pumpApp(
      tester,
      FakeAuthRepository(
        user: const AppUser(id: '1', email: 'a@b.it'),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('il logout riporta al login', (tester) async {
    await pumpApp(
      tester,
      FakeAuthRepository(
        user: const AppUser(id: '1', email: 'a@b.it'),
      ),
    );

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Accedi'), findsWidgets);
  });

  testWidgets('mostra l errore se Supabase non è configurato', (tester) async {
    await tester.pumpWidget(const ConfigErrorApp());
    await tester.pumpAndSettle();

    expect(find.text('Configurazione mancante'), findsOneWidget);
  });
}
