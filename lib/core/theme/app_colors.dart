import 'package:flutter/material.dart';

/// Palette "Crush": tre colori di marca più neutri caldi (chiaro) e inchiostro
/// viola (scuro). Il significato dei colori:
///
/// * **Lampone** (`primary`): azione principale, "mi piace", il crush.
/// * **Indaco** (`secondary`): anonimato e segreto (autore del post, chat,
///   identità).
/// * **Giallo** (`tertiary`): evidenziatore, per novità e avvisi. Si usa solo
///   come riempimento con testo scuro sopra: su sfondo chiaro, come testo o
///   icona, ha contrasto 1,46 e non si legge.
///
/// I contrasti testo/sfondo di tutti i ruoli sono almeno 4,5 (verificati in
/// `test/core/theme/app_theme_test.dart`); fa eccezione `outline` nel tema
/// chiaro (3,58), che serve per i bordi dei componenti e per quelli basta 3.
abstract final class AppColors {
  /// Lampone, nelle due versioni (più scuro sul chiaro, più chiaro sullo
  /// scuro).
  static const raspberry = Color(0xFFD92B48);
  static const raspberryOnDark = Color(0xFFFF6F83);

  /// Indaco.
  static const indigo = Color(0xFF5B49D9);
  static const indigoOnDark = Color(0xFFA99BFF);

  /// Giallo evidenziatore, uguale nei due temi.
  static const highlight = Color(0xFFFFC93C);

  /// Una tinta più scura dello stesso giallo, solo per le sfumature del
  /// marchio (nessun testo).
  static const highlightDeep = Color(0xFFF0B021);

  /// L'inchiostro viola (sfondo del tema scuro, della splash e dell'icona) e
  /// il crema (sfondo del tema chiaro e colore del logo sull'inchiostro).
  static const ink = Color(0xFF16131C);
  static const cream = Color(0xFFFFF8F3);

  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: raspberry,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDADF),
    onPrimaryContainer: Color(0xFF5A0A1B),
    secondary: indigo,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE5E0FF),
    onSecondaryContainer: Color(0xFF1E0F6B),
    tertiary: highlight,
    onTertiary: Color(0xFF1F1B24),
    tertiaryContainer: Color(0xFFFFEDB8),
    onTertiaryContainer: Color(0xFF3A2A00),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: cream,
    onSurface: Color(0xFF1F1B24),
    surfaceDim: Color(0xFFEFDFD6),
    surfaceBright: cream,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFF1EA),
    surfaceContainer: Color(0xFFFBEAE2),
    surfaceContainerHigh: Color(0xFFF6E3DB),
    surfaceContainerHighest: Color(0xFFF0DDD4),
    onSurfaceVariant: Color(0xFF5E5666),
    outline: Color(0xFF8A8092),
    outlineVariant: Color(0xFFE8DAD2),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF322D3A),
    onInverseSurface: Color(0xFFF6F1F7),
    inversePrimary: Color(0xFFFF9AA8),
    surfaceTint: raspberry,
  );

  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: raspberryOnDark,
    onPrimary: Color(0xFF2B0712),
    primaryContainer: Color(0xFF8F1B33),
    onPrimaryContainer: Color(0xFFFFDADF),
    secondary: indigoOnDark,
    onSecondary: Color(0xFF1E0F6B),
    secondaryContainer: Color(0xFF3E3290),
    onSecondaryContainer: Color(0xFFE5E0FF),
    tertiary: highlight,
    onTertiary: Color(0xFF3A2A00),
    tertiaryContainer: Color(0xFF5C4500),
    onTertiaryContainer: Color(0xFFFFEDB8),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: ink,
    onSurface: Color(0xFFF6F1F7),
    surfaceDim: ink,
    surfaceBright: Color(0xFF3B3545),
    surfaceContainerLowest: Color(0xFF100E15),
    surfaceContainerLow: Color(0xFF1B1822),
    surfaceContainer: Color(0xFF221E2B),
    surfaceContainerHigh: Color(0xFF2B2735),
    surfaceContainerHighest: Color(0xFF35303F),
    onSurfaceVariant: Color(0xFFCBC2D3),
    outline: Color(0xFF978EA0),
    outlineVariant: Color(0xFF3F3A48),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF0EAF3),
    onInverseSurface: Color(0xFF1F1B24),
    inversePrimary: raspberry,
    surfaceTint: raspberryOnDark,
  );
}
