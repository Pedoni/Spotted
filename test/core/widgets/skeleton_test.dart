import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart'
    show Bone, ShimmerEffect, Skeletonizer;
import 'package:spotted/core/theme/app_skeleton.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/core/widgets/user_avatar.dart';
import 'package:spotted/l10n/app_localizations.dart';

Widget host(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('Skeleton', () {
    testWidgets('mostra il contenuto come scheletro', (tester) async {
      await tester.pumpWidget(host(const Skeleton(child: Text('Testo finto'))));

      final skeletonizer = tester.widget<Skeletonizer>(
        find.byWidgetPredicate((w) => w is Skeletonizer),
      );
      expect(skeletonizer.enabled, isTrue);
    });

    testWidgets('i tocchi sul contenuto finto sono ignorati', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          Skeleton(
            child: Center(
              child: FilledButton(
                onPressed: () => taps++,
                child: const Text('Apri'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);

      expect(taps, 0);
    });

    testWidgets('un lettore di schermo sente "Caricamento in corso"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const Skeleton(child: Text('Testo finto da non leggere'))),
      );

      expect(find.bySemanticsLabel('Caricamento in corso'), findsOneWidget);
      expect(find.bySemanticsLabel('Testo finto da non leggere'), findsNothing);
      handle.dispose();
    });

    testWidgets('prende i colori dal tema, chiaro e scuro', (tester) async {
      for (final scheme in [
        AppTheme.light.colorScheme,
        AppTheme.dark.colorScheme,
      ]) {
        final config = AppSkeleton.config(scheme);
        final effect = config.resolveEffect(scheme.brightness) as ShimmerEffect;

        expect(effect.colors.first, scheme.surfaceContainerHighest);
        // L'evidenziazione si distingue dal fondo ma non è un altro colore.
        expect(effect.colors[1], isNot(scheme.surfaceContainerHighest));
        expect(config.brightness, scheme.brightness);
      }
    });

    testWidgets('lo shimmer è nei toni della superficie, non accesi', (
      tester,
    ) async {
      final light = AppTheme.light.colorScheme;
      final config = AppSkeleton.config(light);
      final effect = config.resolveEffect(light.brightness) as ShimmerEffect;

      for (final color in effect.colors) {
        // Nessuno dei due colori è un colore di marca.
        expect(color, isNot(light.primary));
        expect(color, isNot(light.secondary));
        expect(color, isNot(light.tertiary));
      }
    });
  });

  group('isSkeleton', () {
    testWidgets('è vero solo dentro uno scheletro', (tester) async {
      bool? inside;
      bool? outside;
      await tester.pumpWidget(
        host(
          Column(
            children: [
              Builder(
                builder: (context) {
                  outside = isSkeleton(context);
                  return const SizedBox();
                },
              ),
              Skeleton(
                child: Builder(
                  builder: (context) {
                    inside = isSkeleton(context);
                    return const Text('x');
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(outside, isFalse);
      expect(inside, isTrue);
    });
  });

  group('avatar nello scheletro', () {
    testWidgets('ChannelAvatar è un riquadro neutro, senza iniziale', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const Skeleton(child: ChannelAvatar(name: 'Spotted Pisa'))),
      );

      expect(find.byWidgetPredicate((w) => w is Bone), findsOneWidget);
      expect(find.text('S'), findsNothing);
    });

    testWidgets('UserAvatar anonimo è un riquadro neutro, senza maschera', (
      tester,
    ) async {
      await tester.pumpWidget(host(const Skeleton(child: UserAvatar())));

      expect(find.byWidgetPredicate((w) => w is Bone), findsOneWidget);
      expect(find.byIcon(Icons.theater_comedy_outlined), findsNothing);
    });

    testWidgets('fuori dallo scheletro restano colorati', (tester) async {
      await tester.pumpWidget(host(const ChannelAvatar(name: 'Spotted Pisa')));

      expect(find.byWidgetPredicate((w) => w is Bone), findsNothing);
      expect(find.text('S'), findsOneWidget);
    });
  });

  group('SkeletonScroll', () {
    testWidgets('taglia un contenuto più alto dello schermo senza errori', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SkeletonScroll(
            child: Column(
              children: [
                for (var i = 0; i < 40; i++)
                  const SizedBox(height: 100, child: Text('riga')),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('non scorre', (tester) async {
      await tester.pumpWidget(
        host(
          SkeletonScroll(
            child: Column(
              children: [
                for (var i = 0; i < 40; i++)
                  const SizedBox(height: 100, child: Text('riga')),
              ],
            ),
          ),
        ),
      );

      final view = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(view.physics, isA<NeverScrollableScrollPhysics>());
    });
  });

  group('InlineProgress', () {
    testWidgets('è un indicatore piccolo, della dimensione richiesta', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const Center(child: InlineProgress(size: 24))),
      );

      expect(tester.getSize(find.byType(InlineProgress)), const Size(24, 24));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
