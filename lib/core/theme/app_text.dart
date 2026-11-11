import 'package:flutter/material.dart';

/// Famiglie di font incluse nell'app (`assets/fonts`, licenza OFL).
abstract final class AppFonts {
  /// Titoli: un po' di carattere senza essere strano (pesi 700 e 800).
  static const display = 'BricolageGrotesque';

  /// Testo e interfaccia: amichevole e leggibile (pesi 400, 500, 600, 700).
  static const body = 'PlusJakartaSans';
}

abstract final class AppTextTheme {
  /// Le dimensioni sono quelle di Material 3; cambiano font e pesi: titoli in
  /// Bricolage Grotesque, tutto il resto in Plus Jakarta Sans.
  static TextTheme build(ColorScheme scheme) {
    final base = Typography.material2021().englishLike.apply(
      fontFamily: AppFonts.body,
      displayColor: scheme.onSurface,
      bodyColor: scheme.onSurface,
    );

    TextStyle? title(TextStyle? style, FontWeight weight) =>
        style?.copyWith(fontFamily: AppFonts.display, fontWeight: weight);
    TextStyle? ui(TextStyle? style, FontWeight weight) =>
        style?.copyWith(fontWeight: weight);

    return base.copyWith(
      displayLarge: title(base.displayLarge, FontWeight.w800),
      displayMedium: title(base.displayMedium, FontWeight.w800),
      displaySmall: title(base.displaySmall, FontWeight.w800),
      headlineLarge: title(base.headlineLarge, FontWeight.w700),
      headlineMedium: title(base.headlineMedium, FontWeight.w700),
      headlineSmall: title(base.headlineSmall, FontWeight.w700),
      titleLarge: title(base.titleLarge, FontWeight.w700),
      titleMedium: ui(base.titleMedium, FontWeight.w600),
      titleSmall: ui(base.titleSmall, FontWeight.w600),
      labelLarge: ui(base.labelLarge, FontWeight.w600),
      labelMedium: ui(base.labelMedium, FontWeight.w600),
      labelSmall: ui(base.labelSmall, FontWeight.w500),
    );
  }
}
