import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/core/widgets/squircle_avatar.dart';
import 'package:spotted/l10n/app_localizations.dart';

Widget host(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

Color avatarColor(WidgetTester tester) {
  final box = tester.widget<Container>(
    find.descendant(
      of: find.byType(SquircleAvatar),
      matching: find.byType(Container),
    ),
  );
  return (box.decoration! as ShapeDecoration).color!;
}

void main() {
  testWidgets('mostra icona, titolo, testo e pulsante', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        EmptyState(
          icon: Icons.search_rounded,
          title: 'Nessun canale',
          message: 'Prova a cercare altro.',
          action: FilledButton(
            onPressed: () => taps++,
            child: const Text('Riparti'),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.text('Nessun canale'), findsOneWidget);
    expect(find.text('Prova a cercare altro.'), findsOneWidget);
    await tester.tap(find.text('Riparti'));
    expect(taps, 1);
  });

  testWidgets('senza testo né pulsante mostra solo icona e titolo', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const EmptyState(icon: Icons.flag_rounded, title: 'Vuoto')),
    );

    expect(find.text('Vuoto'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('l icona è sempre su lampone chiaro, mai indaco', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const EmptyState(icon: Icons.flag_rounded, title: 'Vuoto')),
    );

    final scheme = AppTheme.light.colorScheme;
    expect(avatarColor(tester), scheme.primaryContainer);
    expect(avatarColor(tester), isNot(scheme.secondaryContainer));
  });

  testWidgets('compatto è più piccolo', (tester) async {
    await tester.pumpWidget(
      host(const EmptyState(icon: Icons.flag_rounded, title: 'Vuoto')),
    );
    final normal = tester.getSize(find.byType(SquircleAvatar));

    await tester.pumpWidget(
      host(
        const EmptyState(
          icon: Icons.flag_rounded,
          title: 'Vuoto',
          compact: true,
        ),
      ),
    );
    final compact = tester.getSize(find.byType(SquircleAvatar));

    expect(compact.width, lessThan(normal.width));
  });

  testWidgets('funziona anche nel tema scuro', (tester) async {
    await tester.pumpWidget(
      host(
        const EmptyState(icon: Icons.flag_rounded, title: 'Vuoto'),
        theme: AppTheme.dark,
      ),
    );

    expect(find.text('Vuoto'), findsOneWidget);
    expect(avatarColor(tester), AppTheme.dark.colorScheme.primaryContainer);
  });
}
