import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/app.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/pump_app.dart';

void main() {
  const homeText = 'Non segui ancora nessun canale';

  testWidgets('senza sessione mostra il login', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());

    expect(find.text('Accedi'), findsWidgets);
    expect(find.text(homeText), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('con sessione mostra la home e la barra di navigazione', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text(homeText), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('la barra naviga tra Canali e Profilo', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Cerca un canale'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('@mario_88'), findsOneWidget);
  });

  testWidgets('il logout dal profilo riporta al login', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Accedi'), findsWidgets);
  });

  testWidgets('mostra l errore se Supabase non è configurato', (tester) async {
    await tester.pumpWidget(const ConfigErrorApp());
    await tester.pumpAndSettle();

    expect(find.text('Configurazione mancante'), findsOneWidget);
  });
}
