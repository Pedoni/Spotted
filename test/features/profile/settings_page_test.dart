import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<void> openSettings(
    WidgetTester tester, {
    Map<String, Object> preferences = const {},
  }) async {
    await pumpApp(tester, preferences: preferences);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
  }

  Brightness brightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold).last)).brightness;

  testWidgets('il profilo mostra avatar, username e i miei spot', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('@mario_88'), findsOneWidget);
    expect(find.text('I miei spot'), findsOneWidget);
    expect(find.text('Esci'), findsNothing);
  });

  testWidgets('per default il tema è chiaro', (tester) async {
    await openSettings(tester);

    expect(brightness(tester), Brightness.light);
    final selected = tester
        .widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        )
        .selected;
    expect(selected, {ThemeMode.light});
  });

  testWidgets('scegliere Scuro cambia il tema e lo salva', (tester) async {
    await openSettings(tester);

    await tester.tap(find.text('Scuro'));
    await tester.pumpAndSettle();

    expect(brightness(tester), Brightness.dark);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('theme_mode'), 'dark');
  });

  testWidgets('la scelta salvata viene ripresa', (tester) async {
    await openSettings(tester, preferences: {'theme_mode': 'dark'});

    expect(brightness(tester), Brightness.dark);
  });

  testWidgets('Telefono segue il sistema', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await openSettings(tester);

    await tester.tap(find.text('Telefono'));
    await tester.pumpAndSettle();

    expect(brightness(tester), Brightness.dark);
  });

  testWidgets('Cambia password ed Elimina profilo non fanno nulla', (
    tester,
  ) async {
    await openSettings(tester);

    expect(find.text('Cambia password'), findsOneWidget);
    expect(find.text('Elimina profilo'), findsOneWidget);
    expect(find.text('In arrivo'), findsNWidgets(2));

    await tester.tap(find.text('Cambia password'));
    await tester.tap(find.text('Elimina profilo'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Impostazioni'), findsOneWidget);
  });
}
