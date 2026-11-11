import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/theme/app_colors.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/brand_blobs.dart';
import 'package:spotted/core/widgets/radar_logo.dart';
import 'package:spotted/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:spotted/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:spotted/l10n/app_localizations.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

Widget host({
  bool dark = false,
  bool tall = false,
  Widget? child,
  String title = 'Accedi',
}) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AuthFormLayout(
      title: title,
      tall: tall,
      child: child ?? const Text('modulo'),
    ),
  );
}

/// Uno schermo di [width]x[height] pixel logici.
void screen(WidgetTester tester, double width, double height) {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Il riquadro colorato del foglio.
BoxDecoration sheetOf(WidgetTester tester) {
  final sheet = tester.widget<Container>(
    find
        .ancestor(of: find.text('modulo'), matching: find.byType(Container))
        .last,
  );
  return sheet.decoration! as BoxDecoration;
}

void main() {
  group('marchio in alto', () {
    testWidgets('mostra le macchie, il radar e la scritta', (tester) async {
      await tester.pumpWidget(host());

      expect(find.byType(BrandBlobs), findsOneWidget);
      expect(find.byType(RadarLogo), findsOneWidget);
      expect(find.text('Spotted'), findsOneWidget);
    });

    testWidgets('lo sfondo è l inchiostro viola, anche con il tema chiaro', (
      tester,
    ) async {
      await tester.pumpWidget(host());

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppColors.ink,
      );
    });

    testWidgets('la scritta è color crema, nel font dei titoli', (
      tester,
    ) async {
      await tester.pumpWidget(host());

      final style = tester.widget<Text>(find.text('Spotted')).style!;
      expect(style.color, AppColors.cream);
      expect(style.fontFamily, 'BricolageGrotesque');
      expect(style.fontWeight, FontWeight.w800);
    });

    testWidgets('le icone della barra di stato sono chiare', (tester) async {
      await tester.pumpWidget(host());

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(region.value.statusBarIconBrightness, Brightness.light);
      expect(region.value.statusBarColor, Colors.transparent);
    });

    testWidgets('con tall la parte alta è più alta e il radar più grande', (
      tester,
    ) async {
      screen(tester, 390, 844);
      await tester.pumpWidget(host());
      final normalLogo = tester.getSize(find.byType(RadarLogo)).width;
      final normalSheet = tester.getTopLeft(find.text('Accedi')).dy;

      await tester.pumpWidget(host(tall: true));
      final tallLogo = tester.getSize(find.byType(RadarLogo)).width;
      final tallSheet = tester.getTopLeft(find.text('Accedi')).dy;

      expect(tallLogo, greaterThan(normalLogo));
      expect(tallSheet, greaterThan(normalSheet));
    });
  });

  group('foglio', () {
    testWidgets('mostra il titolo come intestazione e il modulo', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(title: 'Registrati'));

      expect(find.text('Registrati'), findsOneWidget);
      expect(find.text('modulo'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Registrati')),
        matchesSemantics(label: 'Registrati', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('nel tema chiaro è bianco', (tester) async {
      await tester.pumpWidget(host());

      expect(
        sheetOf(tester).color,
        AppTheme.light.colorScheme.surfaceContainerLowest,
      );
    });

    testWidgets('nel tema scuro è più chiaro dello sfondo', (tester) async {
      await tester.pumpWidget(host(dark: true));

      final color = sheetOf(tester).color!;
      expect(color, AppTheme.dark.colorScheme.surfaceContainer);
      expect(
        color.computeLuminance(),
        greaterThan(AppColors.ink.computeLuminance()),
      );
    });

    testWidgets('ha gli angoli in alto arrotondati', (tester) async {
      await tester.pumpWidget(host());

      expect(
        sheetOf(tester).borderRadius,
        const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      );
    });

    testWidgets('riempie lo schermo anche con un modulo breve', (tester) async {
      screen(tester, 390, 844);
      await tester.pumpWidget(host());

      final sheet = find
          .ancestor(
            of: find.text('modulo'),
            matching: find.byType(Container),
          )
          .last;
      expect(tester.getBottomLeft(sheet).dy, greaterThanOrEqualTo(844));
    });
  });

  group('schermi diversi', () {
    testWidgets(
      'su uno schermo piccolo con un modulo lungo scorre senza errori',
      (
        tester,
      ) async {
        screen(tester, 320, 568);
        await tester.pumpWidget(
          host(
            child: Column(
              children: [
                for (var i = 0; i < 12; i++)
                  const SizedBox(height: 90, child: Text('riga')),
              ],
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -2000),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('su uno schermo largo il modulo non si allarga oltre 420', (
      tester,
    ) async {
      screen(tester, 1000, 800);
      await tester.pumpWidget(
        host(child: const SizedBox(height: 20, child: Placeholder())),
      );

      expect(
        tester.getSize(find.byType(Placeholder)).width,
        lessThanOrEqualTo(420),
      );
      // Il foglio, invece, occupa tutta la larghezza.
      final sheet = find
          .ancestor(
            of: find.byType(Placeholder),
            matching: find.byType(Container),
          )
          .last;
      expect(tester.getSize(sheet).width, 1000);
    });

    testWidgets('le macchie coprono la parte alta a tutta larghezza', (
      tester,
    ) async {
      screen(tester, 390, 844);
      await tester.pumpWidget(host());

      expect(tester.getSize(find.byType(BrandBlobs)).width, 390);
    });
  });

  group('nelle pagine', () {
    Finder field(String label) => find.widgetWithText(TextFormField, label);

    testWidgets('l accesso ha il radar più grande della registrazione', (
      tester,
    ) async {
      screen(tester, 390, 844);
      await pumpApp(tester, auth: FakeAuthRepository());
      final loginLogo = tester.getSize(find.byType(RadarLogo)).width;
      expect(find.text('Accedi'), findsWidgets);

      await tester.tap(find.text('Non hai un account? Registrati'));
      await tester.pumpAndSettle();

      expect(find.text('Registrati'), findsWidgets);
      expect(
        tester.getSize(find.byType(RadarLogo)).width,
        lessThan(loginLogo),
      );
    });

    testWidgets('un errore di accesso compare nel riquadro, con icona', (
      tester,
    ) async {
      final repo = FakeAuthRepository()
        ..signInError = const AuthFailure(AuthFailureReason.invalidCredentials);
      await pumpApp(tester, auth: repo);

      await tester.enterText(field('Email'), 'a@b.it');
      await tester.enterText(field('Password'), 'sbagliata');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(AuthErrorBanner), findsOneWidget);
      expect(find.text('Email o password non corretti'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('AuthErrorBanner', () {
    testWidgets('usa i colori del contenitore errore', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AuthErrorBanner(message: 'Qualcosa non va'),
          ),
        ),
      );

      final box =
          tester.widget<Container>(find.byType(Container)).decoration!
              as BoxDecoration;
      expect(box.color, AppTheme.light.colorScheme.errorContainer);
      final text = tester.widget<Text>(find.text('Qualcosa non va'));
      expect(text.style!.color, AppTheme.light.colorScheme.onErrorContainer);
    });

    testWidgets('un lettore di schermo lo annuncia', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AuthErrorBanner(message: 'Qualcosa non va')),
        ),
      );

      expect(
        tester.getSemantics(find.byType(AuthErrorBanner)),
        matchesSemantics(
          label: 'Qualcosa non va',
          isLiveRegion: true,
        ),
      );
      handle.dispose();
    });
  });
}
