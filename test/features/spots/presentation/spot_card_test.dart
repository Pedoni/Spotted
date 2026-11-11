import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';
import 'package:spotted/l10n/app_localizations.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

Widget host(Spot spot, {String? channelName, ThemeData? theme}) {
  return ProviderScope(
    retry: noRetry,
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(user: loggedInUser),
      ),
      spotsRepositoryProvider.overrideWithValue(FakeSpotsRepository()),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SpotCard(spot: spot, channelName: channelName),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('è un fumetto: angolo in basso a sinistra quasi dritto', (
    tester,
  ) async {
    await tester.pumpWidget(host(makeSpot(1)));

    final shape =
        tester.widget<Card>(find.byType(Card)).shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, AppShapes.bubbleRadius);
  });

  testWidgets('ha un bordo sottile del colore del tema', (tester) async {
    await tester.pumpWidget(host(makeSpot(1)));

    final shape =
        tester.widget<Card>(find.byType(Card)).shape! as RoundedRectangleBorder;
    expect(shape.side.color, AppTheme.light.colorScheme.outlineVariant);
    expect(shape.side.width, 1.5);
  });

  testWidgets('il titolo è nel font dei titoli, il testo no', (tester) async {
    await tester.pumpWidget(host(makeSpot(1, title: 'Ombrello perso')));

    final title = tester.widget<Text>(find.text('Ombrello perso'));
    final body = tester.widget<Text>(find.text('Testo dello spot 1'));
    expect(title.style!.fontFamily, 'BricolageGrotesque');
    expect(body.style!.fontFamily, 'PlusJakartaSans');
  });

  testWidgets("con il canale mostra l'avatar e il nome", (tester) async {
    await tester.pumpWidget(host(makeSpot(1), channelName: 'Spotted Pisa'));

    expect(find.byType(ChannelAvatar), findsOneWidget);
    expect(find.textContaining('Spotted Pisa'), findsOneWidget);
    // Il colore dell'avatar dipende dal canale dello spot.
    final avatar = tester.widget<ChannelAvatar>(find.byType(ChannelAvatar));
    expect(avatar.seed, 'c1');
    expect(avatar.name, 'Spotted Pisa');
  });

  testWidgets("senza il canale non c'è l'avatar", (tester) async {
    await tester.pumpWidget(host(makeSpot(1)));

    expect(find.byType(ChannelAvatar), findsNothing);
  });

  testWidgets('uno spot nascosto ha l etichetta in colore errore', (
    tester,
  ) async {
    await tester.pumpWidget(host(makeSpot(1, status: SpotStatus.hidden)));

    final label = tester.widget<Text>(
      find.text('Nascosto dal proprietario del canale'),
    );
    expect(label.style!.color, AppTheme.light.colorScheme.error);
  });

  testWidgets('funziona anche nel tema scuro', (tester) async {
    await tester.pumpWidget(host(makeSpot(1), theme: AppTheme.dark));

    final card = tester.widget<Card>(find.byType(Card));
    // Il colore viene dal tema: più chiaro dello sfondo.
    expect(card.color, isNull);
    expect(
      AppTheme.dark.cardTheme.color!.computeLuminance(),
      greaterThan(AppTheme.dark.scaffoldBackgroundColor.computeLuminance()),
    );
  });
}
