import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('mostra username, nome ed email', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('@mario_88'), findsOneWidget);
    expect(find.text('Mario Rossi'), findsOneWidget);
    expect(find.text('a@b.it'), findsOneWidget);
  });

  testWidgets('senza nome mostra solo lo username', (tester) async {
    await pumpApp(
      tester,
      profile: FakeProfileRepository(
        profile: const Profile(id: '1', username: 'anon_user'),
      ),
    );
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('@anon_user'), findsOneWidget);
  });

  test('fullName unisce nome e cognome', () {
    expect(
      const Profile(id: '1', username: 'u', firstName: 'Mario').fullName,
      'Mario',
    );
    expect(const Profile(id: '1', username: 'u').fullName, isNull);
  });

  group('uscire dall account', () {
    Future<FakeAuthRepository> openProfile(WidgetTester tester) async {
      final auth = FakeAuthRepository(user: loggedInUser);
      await pumpApp(tester, auth: auth);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      return auth;
    }

    testWidgets('toccando Esci chiede conferma e non esce subito', (
      tester,
    ) async {
      final auth = await openProfile(tester);

      await tester.tap(find.text('Esci'));
      await tester.pumpAndSettle();

      expect(find.text("Uscire dall'account?"), findsOneWidget);
      expect(
        find.text('Per usare Spotted dovrai accedere di nuovo.'),
        findsOneWidget,
      );
      expect(auth.signOutCalls, 0);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Annulla chiude la finestra e resta nell account', (
      tester,
    ) async {
      final auth = await openProfile(tester);
      await tester.tap(find.text('Esci'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(find.text("Uscire dall'account?"), findsNothing);
      expect(auth.signOutCalls, 0);
      expect(find.text('@mario_88'), findsOneWidget);
    });

    testWidgets('toccando fuori dalla finestra non esce', (tester) async {
      final auth = await openProfile(tester);
      await tester.tap(find.text('Esci'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text("Uscire dall'account?"), findsNothing);
      expect(auth.signOutCalls, 0);
    });

    testWidgets('Esci nella finestra esce e riporta all accesso', (
      tester,
    ) async {
      final auth = await openProfile(tester);
      await tester.tap(find.text('Esci'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Esci'));
      await tester.pumpAndSettle();

      expect(auth.signOutCalls, 1);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Accedi'), findsWidgets);
    });
  });
}
