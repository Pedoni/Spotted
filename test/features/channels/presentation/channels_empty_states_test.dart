import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Future<void> openChannels(
    WidgetTester tester, {
    List<dynamic>? channels,
  }) async {
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(
        channels: channels?.cast() ?? const [],
      ),
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
  }

  group('Esplora', () {
    testWidgets('senza canali invita a crearne uno', (tester) async {
      await openChannels(tester);

      expect(find.text('Nessun canale trovato'), findsOneWidget);
      expect(
        find.text("Non c'è ancora nessun canale: creane uno!"),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.search_rounded), findsWidgets);
      expect(find.widgetWithText(OutlinedButton, 'Azzera'), findsNothing);
    });

    testWidgets('con una ricerca senza risultati suggerisce di cambiarla', (
      tester,
    ) async {
      await openChannels(tester, channels: [makeChannel(1, name: 'Pisa')]);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Nessun canale trovato'), findsOneWidget);
      expect(
        find.text('Prova a cambiare la ricerca o i filtri.'),
        findsOneWidget,
      );
      // Nessun filtro del foglio: niente "Azzera".
      expect(find.widgetWithText(OutlinedButton, 'Azzera'), findsNothing);
    });

    testWidgets('con i filtri senza risultati c è "Azzera" e li toglie', (
      tester,
    ) async {
      await openChannels(
        tester,
        channels: [makeChannel(1, name: 'Spotted Pisa', topicId: 't-uni')],
      );
      await tester.tap(find.byTooltip('Filtri'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Sport'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Applica'));
      await tester.pumpAndSettle();

      expect(find.text('Nessun canale trovato'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Azzera'));
      await tester.pumpAndSettle();

      expect(find.text('Spotted Pisa'), findsOneWidget);
      expect(find.text('Nessun canale trovato'), findsNothing);
    });
  });

  group('Seguiti', () {
    testWidgets('senza canali seguiti invita a scoprirli', (tester) async {
      await openChannels(tester);
      await tester.tap(find.text('Seguiti'));
      await tester.pumpAndSettle();

      expect(find.text('Non segui ancora nessun canale'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Scopri i canali'),
        findsOneWidget,
      );
    });
  });

  group('Miei', () {
    testWidgets('senza canali propri: invito e pulsante per crearne uno', (
      tester,
    ) async {
      await openChannels(tester);
      await tester.tap(find.text('Miei'));
      await tester.pumpAndSettle();

      expect(find.text('Non hai ancora creato canali'), findsOneWidget);
      expect(
        find.textContaining('Crea un canale per raccogliere'),
        findsOneWidget,
      );

      await tester.tap(find.text('Crea il tuo primo canale'));
      await tester.pumpAndSettle();

      expect(find.text('Nuovo canale'), findsOneWidget);
    });
  });
}
