import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

/// Dopo l'uscita, chi accede dallo stesso telefono non deve trovare niente
/// della persona di prima: né dati, né "mi piace", né ricerche, né la scheda
/// in cui era.
void main() {
  testWidgets('un altro utente che accede non trova lo stato del precedente', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: loggedInUser);
    final profile = FakeProfileRepository();
    await pumpApp(
      tester,
      auth: auth,
      profile: profile,
      spots: FakeSpotsRepository(mine: [makeMySpot(1)]),
      screenSize: tallScreen,
    );

    // L'utente A mette un "mi piace", scrive una ricerca nei canali e apre il
    // profilo.
    await tester.tap(find.byTooltip('Visualizza tutti'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pisa');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('@mario_88'), findsOneWidget);

    // Esce.
    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Esci'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);

    // Accede un'altra persona.
    profile.profile = const Profile(id: '2', username: 'luigi_99');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'luigi@b.it',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // Riparte dalla Home, senza il "mi piace" di A.
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
    await tester.tap(find.byTooltip('Visualizza tutti'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();

    // Senza la ricerca di A nei canali.
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'pisa'), findsNothing);

    // E il profilo è il suo, non quello di A.
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('@luigi_99'), findsOneWidget);
    expect(find.text('@mario_88'), findsNothing);
  });
}
