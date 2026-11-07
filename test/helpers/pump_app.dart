import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/app.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';

import 'fake_auth_repository.dart';

/// Avvia l'app con un repository di autenticazione finto.
Future<void> pumpApp(WidgetTester tester, FakeAuthRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}
