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
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
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
    // I propri spot stanno nella Home.
    expect(find.text('I miei spot'), findsNothing);
  });

  testWidgets('se il profilo non si carica restano tema e uscita', (
    tester,
  ) async {
    await pumpApp(
      tester,
      profile: FakeProfileRepository()..error = const NetworkFailure(),
      screenSize: tallScreen,
    );
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
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

  /// Le voci che ci sono ma ancora non fanno niente.
  const soon = [
    'Modifica i miei dati',
    'Notifiche',
    'Privacy',
    "Condizioni d'uso",
    'Elimina profilo',
  ];

  testWidgets('le voci in arrivo ci sono, spente e con scritto "In arrivo"', (
    tester,
  ) async {
    await openProfile(tester);

    for (final title in soon) {
      expect(find.text(title), findsOneWidget, reason: title);
      final tile = tester.widget<ListTile>(
        find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
      );
      expect(tile.enabled, isFalse, reason: title);
    }
    expect(find.text('In arrivo'), findsNWidgets(soon.length));
  });

  testWidgets('toccare le voci in arrivo non fa niente', (tester) async {
    await openProfile(tester);

    for (final title in soon) {
      await tester.tap(find.text(title));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('@mario_88'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
  });

  testWidgets('le voci sono raggruppate in Account e Informazioni', (
    tester,
  ) async {
    await openProfile(tester);

    final account = tester.getRect(find.text('Account')).top;
    final info = tester.getRect(find.text('Informazioni')).top;
    final data = tester.getRect(find.text('Modifica i miei dati')).top;
    final email = tester.getRect(find.text('Cambia email')).top;
    final privacy = tester.getRect(find.text('Privacy')).top;
    final about = tester.getRect(find.text("Informazioni sull'app")).top;

    expect(account, lessThan(data));
    expect(email, lessThan(info));
    expect(info, lessThan(about));
    expect(about, lessThan(privacy));
  });

  testWidgets('Informazioni sull app è l unica voce attiva delle due liste', (
    tester,
  ) async {
    await openProfile(tester);

    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text("Informazioni sull'app"),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.enabled, isTrue);
    expect(tile.onTap, isNotNull);
  });
}
