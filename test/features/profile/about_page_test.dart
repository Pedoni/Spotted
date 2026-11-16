import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/app_info/app_info.dart';
import 'package:spotted/core/licenses/font_licenses.dart';
import 'package:spotted/core/widgets/radar_logo.dart';

import '../../helpers/fake_asset_bundle.dart';
import '../../helpers/pump_app.dart';

/// I testi delle licenze dei font, finti e subito disponibili.
FakeAssetBundle fontBundle() => FakeAssetBundle({
  for (final font in fontLicenses)
    font.asset: 'SIL OPEN FONT LICENSE di ${font.name}',
});

void main() {
  Future<void> openAbout(
    WidgetTester tester, {
    Future<AppInfo> Function()? info,
  }) async {
    await pumpApp(
      tester,
      appInfo: info,
      screenSize: tallScreen,
      settle: info == null,
    );
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text("Informazioni sull'app"));
    await tester.pump(const Duration(milliseconds: 800));
    // Con una versione che si legge subito si aspetta che compaia; se la
    // lettura resta in sospeso (scheletro) l'animazione non finisce mai.
    if (info == null) await tester.pumpAndSettle();
  }

  group('pagina', () {
    testWidgets('si apre dal profilo con titolo, nome e descrizione', (
      tester,
    ) async {
      await openAbout(tester);

      expect(find.text("Informazioni sull'app"), findsOneWidget);
      expect(find.text('Spotted'), findsOneWidget);
      expect(
        find.text('Gli spotted di tutta Italia, in un posto solo.'),
        findsOneWidget,
      );
      expect(find.byType(RadarLogo), findsOneWidget);
    });

    testWidgets('mostra la versione e il numero di build', (tester) async {
      await openAbout(tester);

      expect(find.text('Versione'), findsOneWidget);
      expect(find.text('0.8.0 (1)'), findsOneWidget);
    });

    testWidgets('con un altra versione mostra quella', (tester) async {
      await openAbout(
        tester,
        info: () => Future.value(
          const AppInfo(version: '1.2.3', buildNumber: '45'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1.2.3 (45)'), findsOneWidget);
    });

    testWidgets('senza numero di build mostra solo la versione', (
      tester,
    ) async {
      await openAbout(
        tester,
        info: () =>
            Future.value(const AppInfo(version: '1.2.3', buildNumber: '')),
      );
      await tester.pumpAndSettle();

      expect(find.text('1.2.3'), findsOneWidget);
    });

    testWidgets('mentre legge la versione la riga è uno scheletro', (
      tester,
    ) async {
      final hold = Completer<AppInfo>();
      await openAbout(tester, info: () => hold.future);

      expect(find.text('Versione'), findsOneWidget);
      expect(find.text('0.8.0 (1)'), findsNothing);

      hold.complete(testAppInfo);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('0.8.0 (1)'), findsOneWidget);
    });

    testWidgets('se la versione non si legge la pagina funziona lo stesso', (
      tester,
    ) async {
      await openAbout(
        tester,
        info: () => Future<AppInfo>.error(Exception('nessuna versione')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Spotted'), findsOneWidget);
      expect(find.text('Licenze open source'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('si torna al profilo', (tester) async {
      await openAbout(tester);

      await tester.tap(find.byTooltip('Indietro'));
      await tester.pumpAndSettle();

      expect(find.text('@mario_88'), findsOneWidget);
    });
  });

  group('licenze', () {
    testWidgets('"Licenze open source" apre la pagina delle licenze', (
      tester,
    ) async {
      await openAbout(tester);

      await tester.tap(find.text('Licenze open source'));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.text('Spotted'), findsWidgets);
    });

    testWidgets('tra le licenze ci sono anche quelle dei font dell app', (
      tester,
    ) async {
      // Come fa `main` all'avvio.
      LicenseRegistry.reset();
      addTearDown(LicenseRegistry.reset);
      registerFontLicenses(fontBundle());
      await openAbout(tester);

      await tester.tap(find.text('Licenze open source'));
      await tester.pumpAndSettle();

      expect(find.text('Bricolage Grotesque (font)'), findsOneWidget);
      expect(find.text('Plus Jakarta Sans (font)'), findsOneWidget);
    });

    testWidgets('toccando un font si legge il testo della licenza', (
      tester,
    ) async {
      LicenseRegistry.reset();
      addTearDown(LicenseRegistry.reset);
      registerFontLicenses(fontBundle());
      await openAbout(tester);
      await tester.tap(find.text('Licenze open source'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plus Jakarta Sans (font)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('SIL OPEN FONT LICENSE'), findsWidgets);
    });

    testWidgets('dalle licenze si torna alla pagina informazioni', (
      tester,
    ) async {
      await openAbout(tester);
      await tester.tap(find.text('Licenze open source'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Indietro'));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsNothing);
      expect(find.text('Versione'), findsOneWidget);
    });
  });

  group('AppInfo', () {
    test('label: versione e build tra parentesi', () {
      expect(
        const AppInfo(version: '0.8.0', buildNumber: '1').label,
        '0.8.0 (1)',
      );
    });

    test('label senza build: solo la versione', () {
      expect(const AppInfo(version: '0.8.0', buildNumber: '').label, '0.8.0');
    });

    test('due versioni uguali sono uguali', () {
      expect(
        const AppInfo(version: '1', buildNumber: '2'),
        const AppInfo(version: '1', buildNumber: '2'),
      );
    });
  });
}
