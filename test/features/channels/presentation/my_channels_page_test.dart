import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Future<void> openMyChannels(
    WidgetTester tester,
    FakeChannelsRepository repository,
  ) async {
    await pumpApp(tester, channels: repository);
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Miei'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra solo i canali dell utente', (tester) async {
    final repo = FakeChannelsRepository(
      channels: [
        makeChannel(1, name: 'Altrui'),
        makeChannel(2, name: 'Mio'),
      ],
      mine: [makeChannel(2, name: 'Mio')],
    );
    await openMyChannels(tester, repo);

    expect(find.text('Mio'), findsOneWidget);
    expect(find.text('Altrui'), findsNothing);
  });

  testWidgets('senza canali mostra il messaggio', (tester) async {
    await openMyChannels(tester, FakeChannelsRepository());

    expect(find.text('Non hai ancora creato canali'), findsOneWidget);
  });
}
