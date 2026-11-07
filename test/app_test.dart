import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/app.dart';

void main() {
  testWidgets('shows the home page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('shows the config error when Supabase is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(const ConfigErrorApp());
    await tester.pumpAndSettle();

    expect(find.text('Configurazione mancante'), findsOneWidget);
  });
}
