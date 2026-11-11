import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';

Widget host(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

/// Il colore di sfondo dell'avatar.
Color backgroundOf(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(ChannelAvatar),
      matching: find.byType(Container),
    ),
  );
  return (container.decoration! as ShapeDecoration).color!;
}

void main() {
  testWidgets("mostra l'iniziale in maiuscolo", (tester) async {
    await tester.pumpWidget(host(const ChannelAvatar(name: 'spotted pisa')));

    expect(find.text('S'), findsOneWidget);
  });

  testWidgets('senza nome mostra un punto interrogativo', (tester) async {
    await tester.pumpWidget(host(const ChannelAvatar(name: '   ')));

    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('ha la dimensione richiesta, quadrata', (tester) async {
    await tester.pumpWidget(
      host(const ChannelAvatar(name: 'Canale', size: 60)),
    );

    expect(tester.getSize(find.byType(ChannelAvatar)), const Size(60, 60));
  });

  testWidgets('la forma è un quadrato morbido, non un cerchio', (tester) async {
    await tester.pumpWidget(host(const ChannelAvatar(name: 'Canale')));

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(ChannelAvatar),
        matching: find.byType(Container),
      ),
    );
    expect(
      (container.decoration! as ShapeDecoration).shape,
      isA<RoundedSuperellipseBorder>(),
    );
  });

  testWidgets('lo stesso seed dà sempre lo stesso colore', (tester) async {
    await tester.pumpWidget(
      host(const ChannelAvatar(name: 'Uno', seed: 'abc-123')),
    );
    final first = backgroundOf(tester);

    await tester.pumpWidget(
      host(const ChannelAvatar(name: 'Altro nome', seed: 'abc-123')),
    );

    expect(backgroundOf(tester), first);
  });

  testWidgets('senza seed il colore dipende dal nome', (tester) async {
    await tester.pumpWidget(host(const ChannelAvatar(name: 'Spotted Pisa')));
    final first = backgroundOf(tester);

    await tester.pumpWidget(host(const ChannelAvatar(name: 'Spotted Pisa')));

    expect(backgroundOf(tester), first);
  });

  test('il colore è sempre uno della palette e si distribuisce', () {
    final scheme = AppTheme.light.colorScheme;
    final colors = ChannelAvatar.palette(scheme);
    final used = <int>{};
    for (var i = 0; i < 60; i++) {
      final index = ChannelAvatar.colorIndex('canale-$i', colors.length);
      expect(index, inInclusiveRange(0, colors.length - 1));
      used.add(index);
    }
    // Con tanti canali compaiono quasi tutti i colori.
    expect(used.length, greaterThanOrEqualTo(5));
  });

  test("l'hash è stabile (non dipende dalla sessione)", () {
    // 'a' vale 97; 97 % 6 == 1.
    expect(ChannelAvatar.colorIndex('a', 6), 1);
    expect(ChannelAvatar.colorIndex('', 6), 0);
  });

  test('ogni coppia della palette ha testo leggibile sullo sfondo', () {
    for (final scheme in [
      AppTheme.light.colorScheme,
      AppTheme.dark.colorScheme,
    ]) {
      for (final (background, foreground) in ChannelAvatar.palette(scheme)) {
        final l1 = background.computeLuminance();
        final l2 = foreground.computeLuminance();
        final ratio =
            (l1 > l2 ? l1 + 0.05 : l2 + 0.05) /
            (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
    }
  });
}
