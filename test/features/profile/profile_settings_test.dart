import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotted/core/error/failure.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  Future<void> openProfile(
    WidgetTester tester, {
    Map<String, Object> preferences = const {},
  }) async {
    await pumpApp(tester, preferences: preferences, screenSize: tallScreen);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
  }

  Brightness brightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold).last)).brightness;

  testWidgets('il profilo ha tema, account e uscita sotto nome e foto', (
    tester,
  ) async {
    await openProfile(tester);

    expect(find.text('@mario_88'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Esci'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });

  testWidgets('se il profilo non si carica restano tema e uscita', (
    tester,
  ) async {
    await pumpApp(
      tester,
      profile: FakeProfileRepository()..error = const NetworkFailure(),
      screenSize: tallScreen,
    );
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
    expect(find.text('Esci'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
  });

  testWidgets('per default il tema è chiaro', (tester) async {
    await openProfile(tester);

    expect(brightness(tester), Brightness.light);
    final selected = tester
        .widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        )
        .selected;
    expect(selected, {ThemeMode.light});
  });

  testWidgets('scegliere Scuro cambia il tema e lo salva', (tester) async {
    await openProfile(tester);

    await tester.tap(find.text('Scuro'));
    await tester.pumpAndSettle();

    expect(brightness(tester), Brightness.dark);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('theme_mode'), 'dark');
  });

  testWidgets('la scelta salvata viene ripresa', (tester) async {
    await openProfile(tester, preferences: {'theme_mode': 'dark'});

    expect(brightness(tester), Brightness.dark);
  });

  testWidgets('Telefono segue il sistema', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await openProfile(tester);

    await tester.tap(find.text('Telefono'));
    await tester.pumpAndSettle();

    expect(brightness(tester), Brightness.dark);
  });

  testWidgets('Cambia password ed Elimina profilo non fanno nulla', (
    tester,
  ) async {
    await openProfile(tester);

    expect(find.text('Cambia password'), findsOneWidget);
    expect(find.text('Elimina profilo'), findsOneWidget);
    expect(find.text('In arrivo'), findsNWidgets(2));

    await tester.tap(find.text('Cambia password'));
    await tester.tap(find.text('Elimina profilo'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('@mario_88'), findsOneWidget);
  });
}
