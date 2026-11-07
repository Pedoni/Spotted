import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';

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
}
