import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('la barra ha quattro schede: Home, Canali, Chat, Profilo', (
    tester,
  ) async {
    await pumpApp(tester);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations.length, 4);
    for (final label in ['Home', 'Canali', 'Chat', 'Profilo']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('Canali ha tre viste e parte da Esplora', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Esplora'), findsOneWidget);
    expect(find.text('Seguiti'), findsOneWidget);
    expect(find.text('Miei'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Seguiti senza canali invita a esplorare e porta a Esplora', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguiti'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });
}
