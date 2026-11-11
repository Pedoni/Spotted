import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/like_button.dart';
import 'package:spotted/l10n/app_localizations.dart';

Widget host({required bool liked, int count = 3, VoidCallback? onPressed}) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: LikeButton(
          liked: liked,
          count: count,
          onPressed: onPressed ?? () {},
        ),
      ),
    ),
  );
}

double scaleOf(WidgetTester tester) {
  // Il rimbalzo è sul cuore: l'unico ScaleTransition con un'icona dentro.
  final heart = find.byWidgetPredicate(
    (widget) => widget is ScaleTransition && widget.child is Icon,
  );
  return tester.widget<ScaleTransition>(heart).scale.value;
}

void main() {
  testWidgets('mostra il conteggio e il cuore vuoto se non piace', (
    tester,
  ) async {
    await tester.pumpWidget(host(liked: false, count: 7));

    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('se piace il cuore è pieno e color lampone', (tester) async {
    await tester.pumpWidget(host(liked: true));

    final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
    expect(icon.color, AppTheme.light.colorScheme.primary);
  });

  testWidgets('toccandolo chiama onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(liked: false, onPressed: () => taps++));

    await tester.tap(find.byType(LikeButton));

    expect(taps, 1);
  });

  testWidgets('quando il like viene messo il cuore rimbalza', (tester) async {
    await tester.pumpWidget(host(liked: false));
    expect(scaleOf(tester), 1);

    await tester.pumpWidget(host(liked: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(scaleOf(tester), greaterThan(1));

    await tester.pumpAndSettle();
    expect(scaleOf(tester), closeTo(1, 0.001));
  });

  testWidgets('quando il like viene tolto non rimbalza', (tester) async {
    await tester.pumpWidget(host(liked: true));

    await tester.pumpWidget(host(liked: false));
    await tester.pump(const Duration(milliseconds: 100));

    expect(scaleOf(tester), 1);
  });

  testWidgets('cambiare solo il conteggio non anima', (tester) async {
    await tester.pumpWidget(host(liked: true));

    await tester.pumpWidget(host(liked: true, count: 4));
    await tester.pump(const Duration(milliseconds: 100));

    expect(scaleOf(tester), 1);
  });
}
