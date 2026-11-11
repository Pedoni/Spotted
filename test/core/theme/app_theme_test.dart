import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_colors.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/theme/app_text.dart';
import 'package:spotted/core/theme/app_theme.dart';

/// Rapporto di contrasto WCAG tra due colori.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  final schemes = {'chiaro': AppColors.light, 'scuro': AppColors.dark};

  group('palette Crush', () {
    test('i colori di marca sono quelli scelti', () {
      expect(AppColors.light.primary, AppColors.raspberry);
      expect(AppColors.dark.primary, AppColors.raspberryOnDark);
      expect(AppColors.light.secondary, AppColors.indigo);
      expect(AppColors.dark.secondary, AppColors.indigoOnDark);
      // Il giallo è lo stesso nei due temi.
      expect(AppColors.light.tertiary, AppColors.highlight);
      expect(AppColors.dark.tertiary, AppColors.highlight);
    });

    for (final entry in schemes.entries) {
      final scheme = entry.value;

      test('tema ${entry.key}: ogni testo ha contrasto almeno 4,5', () {
        final pairs = <String, (Color, Color)>{
          'onPrimary/primary': (scheme.onPrimary, scheme.primary),
          'onPrimaryContainer/primaryContainer': (
            scheme.onPrimaryContainer,
            scheme.primaryContainer,
          ),
          'onSecondary/secondary': (scheme.onSecondary, scheme.secondary),
          'onSecondaryContainer/secondaryContainer': (
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
          ),
          'onTertiary/tertiary': (scheme.onTertiary, scheme.tertiary),
          'onTertiaryContainer/tertiaryContainer': (
            scheme.onTertiaryContainer,
            scheme.tertiaryContainer,
          ),
          'onError/error': (scheme.onError, scheme.error),
          'onErrorContainer/errorContainer': (
            scheme.onErrorContainer,
            scheme.errorContainer,
          ),
          'onSurface/surface': (scheme.onSurface, scheme.surface),
          'onSurface/surfaceContainerLowest': (
            scheme.onSurface,
            scheme.surfaceContainerLowest,
          ),
          'onSurface/surfaceContainer': (
            scheme.onSurface,
            scheme.surfaceContainer,
          ),
          'onSurface/surfaceContainerHighest': (
            scheme.onSurface,
            scheme.surfaceContainerHighest,
          ),
          'onSurfaceVariant/surface': (
            scheme.onSurfaceVariant,
            scheme.surface,
          ),
          'onSurfaceVariant/surfaceContainer': (
            scheme.onSurfaceVariant,
            scheme.surfaceContainer,
          ),
          'onSurfaceVariant/surfaceContainerHighest': (
            scheme.onSurfaceVariant,
            scheme.surfaceContainerHighest,
          ),
          'onInverseSurface/inverseSurface': (
            scheme.onInverseSurface,
            scheme.inverseSurface,
          ),
          // Lampone e indaco usati come testo sullo sfondo.
          'primary/surface': (scheme.primary, scheme.surface),
          'secondary/surface': (scheme.secondary, scheme.surface),
        };
        for (final MapEntry(:key, :value) in pairs.entries) {
          expect(
            contrast(value.$1, value.$2),
            greaterThanOrEqualTo(4.5),
            reason: key,
          );
        }
      });

      test('tema ${entry.key}: i bordi hanno contrasto almeno 3', () {
        expect(
          contrast(scheme.outline, scheme.surface),
          greaterThanOrEqualTo(3),
        );
      });
    }

    test('il giallo non si legge come testo su sfondo chiaro', () {
      // È la ragione per cui il giallo è solo un riempimento con testo scuro.
      expect(
        contrast(AppColors.highlight, AppColors.light.surface),
        lessThan(3),
      );
    });

    test(
      'nel tema scuro le superfici sollevate sono più chiare dello sfondo',
      () {
        final theme = AppTheme.dark;
        expect(
          theme.cardTheme.color!.computeLuminance(),
          greaterThan(AppColors.dark.surface.computeLuminance()),
        );
      },
    );

    test(
      'raised dà bianco nel chiaro e una superficie più chiara nello scuro',
      () {
        expect(
          AppTheme.raised(AppColors.light),
          AppColors.light.surfaceContainerLowest,
        );
        expect(
          AppTheme.raised(AppColors.dark),
          AppColors.dark.surfaceContainer,
        );
        expect(
          AppTheme.raised(AppColors.light),
          AppTheme.light.cardTheme.color,
        );
        expect(AppTheme.raised(AppColors.dark), AppTheme.dark.cardTheme.color);
      },
    );

    test('inchiostro e crema sono gli sfondi dei due temi', () {
      expect(AppColors.ink, AppColors.dark.surface);
      expect(AppColors.cream, AppColors.light.surface);
      expect(AppColors.ink, const Color(0xFF16131C));
      expect(AppColors.cream, const Color(0xFFFFF8F3));
    });

    test('la tinta più scura del giallo resta gialla, non arancio', () {
      HSLColor hsl(Color c) => HSLColor.fromColor(c);
      final base = hsl(AppColors.highlight).hue;
      final deep = hsl(AppColors.highlightDeep).hue;
      // Pochi gradi di differenza: è lo stesso giallo, solo più scuro.
      expect((base - deep).abs(), lessThan(8));
      expect(
        hsl(AppColors.highlightDeep).lightness,
        lessThan(hsl(AppColors.highlight).lightness),
      );
    });

    test('nel tema chiaro le card sono bianche sullo sfondo crema', () {
      expect(AppTheme.light.cardTheme.color, const Color(0xFFFFFFFF));
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.light.surface);
    });
  });

  group('tema', () {
    test('è Material 3 e usa le palette', () {
      expect(AppTheme.light.useMaterial3, isTrue);
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.light.colorScheme, AppColors.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.dark.colorScheme, AppColors.dark);
    });

    for (final theme in {
      'chiaro': AppTheme.light,
      'scuro': AppTheme.dark,
    }.entries) {
      final text = theme.value.textTheme;

      test('tema ${theme.key}: titoli in Bricolage Grotesque', () {
        for (final style in [
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
        ]) {
          expect(style!.fontFamily, AppFonts.display);
        }
        expect(text.displaySmall!.fontWeight, FontWeight.w800);
        expect(text.headlineSmall!.fontWeight, FontWeight.w700);
        expect(text.titleLarge!.fontWeight, FontWeight.w700);
      });

      test('tema ${theme.key}: il resto in Plus Jakarta Sans', () {
        for (final style in [
          text.titleMedium,
          text.titleSmall,
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall,
        ]) {
          expect(style!.fontFamily, AppFonts.body);
        }
      });

      test("tema ${theme.key}: usa solo i pesi inclusi nell'app", () {
        final displayWeights = {FontWeight.w700, FontWeight.w800};
        final bodyWeights = {
          FontWeight.w400,
          FontWeight.w500,
          FontWeight.w600,
          FontWeight.w700,
        };
        for (final style in [
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
          text.titleMedium,
          text.titleSmall,
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall,
        ]) {
          final weights = style!.fontFamily == AppFonts.display
              ? displayWeights
              : bodyWeights;
          expect(weights, contains(style.fontWeight));
        }
      });

      test('tema ${theme.key}: il testo prende il colore del tema', () {
        expect(text.bodyMedium!.color, theme.value.colorScheme.onSurface);
        expect(text.headlineSmall!.color, theme.value.colorScheme.onSurface);
      });
    }

    test('i bottoni sono a pillola e abbastanza alti', () {
      final theme = AppTheme.light;
      for (final style in [
        theme.filledButtonTheme.style!,
        theme.elevatedButtonTheme.style!,
        theme.outlinedButtonTheme.style!,
        theme.textButtonTheme.style!,
      ]) {
        expect(style.shape!.resolve({}), isA<StadiumBorder>());
      }
      expect(
        theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height,
        greaterThanOrEqualTo(48),
      );
    });

    test('card e finestre hanno angoli grandi', () {
      final theme = AppTheme.light;
      final card = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(card.borderRadius, BorderRadius.circular(AppRadius.lg));
      final dialog = theme.dialogTheme.shape! as RoundedRectangleBorder;
      expect(dialog.borderRadius, BorderRadius.circular(AppRadius.lg));
    });

    test(
      'i campi di testo hanno angoli morbidi e il bordo si colora al focus',
      () {
        final theme = AppTheme.light;
        final decoration = theme.inputDecorationTheme;
        final border = decoration.border! as OutlineInputBorder;
        expect(border.borderRadius, BorderRadius.circular(AppRadius.md));
        expect(
          (decoration.focusedBorder! as OutlineInputBorder).borderSide.color,
          AppColors.light.primary,
        );
      },
    );

    test('chip e barra di navigazione sono a pillola', () {
      final theme = AppTheme.light;
      expect(theme.chipTheme.shape, isA<StadiumBorder>());
      expect(theme.navigationBarTheme.indicatorShape, isA<StadiumBorder>());
    });
  });

  group('forme', () {
    test("il fumetto ha l'angolo in basso a sinistra quasi dritto", () {
      const radius = AppShapes.bubbleRadius;
      expect(radius.bottomLeft, const Radius.circular(AppRadius.bubbleCorner));
      expect(radius.topLeft, const Radius.circular(AppRadius.lg));
      expect(radius.topRight, const Radius.circular(AppRadius.lg));
      expect(radius.bottomRight, const Radius.circular(AppRadius.lg));
    });

    test('la coda dei messaggi è dalla parte di chi scrive', () {
      final mine = AppShapes.messageRadius(mine: true);
      final theirs = AppShapes.messageRadius(mine: false);
      expect(mine.bottomRight.x, AppRadius.bubbleCorner);
      expect(mine.bottomLeft.x, greaterThan(AppRadius.bubbleCorner));
      expect(theirs.bottomLeft.x, AppRadius.bubbleCorner);
      expect(theirs.bottomRight.x, greaterThan(AppRadius.bubbleCorner));
    });
  });

  group('font inclusi', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(
      r'asset:\s*(assets/fonts/\S+)',
    ).allMatches(pubspec).map((m) => m.group(1)!).toList();

    test('pubspec dichiara le due famiglie del tema', () {
      expect(pubspec, contains('family: ${AppFonts.display}'));
      expect(pubspec, contains('family: ${AppFonts.body}'));
    });

    test('ogni file dichiarato esiste', () {
      expect(assets, hasLength(6));
      for (final path in assets) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('le licenze OFL sono incluse', () {
      expect(
        File('assets/fonts/OFL-BricolageGrotesque.txt').existsSync(),
        isTrue,
      );
      expect(File('assets/fonts/OFL-PlusJakartaSans.txt').existsSync(), isTrue);
    });
  });
}
