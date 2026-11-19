import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/fake_tags.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> openForm(
    WidgetTester tester,
    FakeSpotsRepository spots, {
    bool owner = false,
    FakeTagsRepository? tags,
  }) async {
    final moderation = FakeModerationRepository(
      ownedChannelIds: owner ? {'c1'} : const {},
      spotsRepository: spots,
    );
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots: spots,
      moderation: moderation,
      tags: tags,
      screenSize: const Size(800, 1400),
    );
    await tester.tap(find.byIcon(Icons.tag_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pubblica uno spot'));
    await tester.pumpAndSettle();
  }

  group('un utente qualunque', () {
    testWidgets('il form avvisa che lo spot è anonimo e va approvato', (
      tester,
    ) async {
      await openForm(tester, FakeSpotsRepository());

      expect(
        find.text(
          'Lo spot è anonimo: solo il proprietario del canale può vedere chi '
          'lo ha scritto.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('deve approvare lo spot'), findsOneWidget);
    });

    testWidgets('non sceglie i tag', (tester) async {
      final tags = FakeTagsRepository();
      await openForm(tester, FakeSpotsRepository(), tags: tags);

      expect(find.byType(FilterChip), findsNothing);
      expect(find.text('Invia lo spot'), findsOneWidget);
      // I tag non si scaricano nemmeno.
      expect(tags.channelCalls, isEmpty);
    });

    testWidgets('titolo e testo sono obbligatori', (tester) async {
      final spots = FakeSpotsRepository();
      await openForm(tester, spots);

      await tester.enterText(field('Titolo'), '   ');
      await tester.tap(find.text('Invia lo spot'));
      await tester.pump();

      expect(find.text('Campo obbligatorio'), findsNWidgets(2));
      expect(spots.createCalls, isEmpty);
    });

    testWidgets('invia lo spot: resta in attesa e non compare nel canale', (
      tester,
    ) async {
      final spots = FakeSpotsRepository();
      await openForm(tester, spots);

      await tester.enterText(field('Titolo'), '  Ombrello perso  ');
      await tester.enterText(field('Testo'), 'Blu, lasciato in aula 5');
      await tester.tap(find.text('Invia lo spot'));
      await tester.pumpAndSettle();

      expect(spots.createCalls.single, {
        'channelId': 'c1',
        'title': 'Ombrello perso',
        'content': 'Blu, lasciato in aula 5',
      });
      // Senza tag: lo spot nasce in attesa.
      expect(spots.createTagCalls.single, isNull);
      expect(spots.spots.single.status, SpotStatus.pending);
      expect(
        find.text('Spot inviato: comparirà quando il proprietario lo approva'),
        findsOneWidget,
      );
      // Siamo tornati sul canale: il form è chiuso e lo spot non c'è ancora.
      expect(find.text('Invia lo spot'), findsNothing);
      expect(find.text('Ombrello perso'), findsNothing);
    });

    testWidgets('errore di rete: messaggio e resta sul form', (tester) async {
      final spots = FakeSpotsRepository()..createError = const NetworkFailure();
      await openForm(tester, spots);

      await tester.enterText(field('Titolo'), 'Titolo');
      await tester.enterText(field('Testo'), 'Testo');
      await tester.tap(find.text('Invia lo spot'));
      await tester.pumpAndSettle();

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('Invia lo spot'), findsOneWidget);
    });
  });

  group('il proprietario del canale', () {
    Future<void> fill(WidgetTester tester) async {
      await tester.enterText(field('Titolo'), 'Ombrello perso');
      await tester.enterText(field('Testo'), 'Blu, lasciato in aula 5');
    }

    testWidgets('sceglie i tag e non vede la nota sull approvazione', (
      tester,
    ) async {
      final tags = FakeTagsRepository();
      await openForm(tester, FakeSpotsRepository(), owner: true, tags: tags);

      expect(find.text('Scegli da 1 a 3 tag'), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(fakeTags.length));
      // Raggruppati per categoria.
      expect(find.text('Generici'), findsOneWidget);
      expect(find.text('Didattica e studio'), findsOneWidget);
      expect(tags.channelCalls, ['c1']);
      expect(find.textContaining('deve approvare lo spot'), findsNothing);
      expect(find.text('Pubblica'), findsOneWidget);
    });

    testWidgets('senza tag non pubblica e lo dice', (tester) async {
      final spots = FakeSpotsRepository();
      await openForm(tester, spots, owner: true);
      await fill(tester);

      await tester.tap(find.text('Pubblica'));
      await tester.pumpAndSettle();

      expect(find.text('Scegli almeno un tag'), findsOneWidget);
      expect(spots.createCalls, isEmpty);

      // Scegliendone uno l'avviso sparisce.
      await tester.tap(find.widgetWithText(FilterChip, 'Crush'));
      await tester.pump();
      expect(find.text('Scegli almeno un tag'), findsNothing);
    });

    testWidgets('al massimo tre tag: gli altri si disattivano', (tester) async {
      await openForm(tester, FakeSpotsRepository(), owner: true);

      for (final label in ['Crush', 'Curiosità', 'Meme']) {
        await tester.tap(find.widgetWithText(FilterChip, label));
        await tester.pump();
      }

      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Esami'))
            .onSelected,
        isNull,
      );

      // Togliendone uno si può sceglierne un altro.
      await tester.tap(find.widgetWithText(FilterChip, 'Meme'));
      await tester.pump();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Esami'))
            .onSelected,
        isNotNull,
      );
    });

    testWidgets('pubblica subito con i tag e lo spot compare nel canale', (
      tester,
    ) async {
      final spots = FakeSpotsRepository();
      await openForm(tester, spots, owner: true);
      await fill(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Crush'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'Esami'));
      await tester.pump();
      await tester.tap(find.text('Pubblica'));
      await tester.pumpAndSettle();

      expect(spots.createTagCalls.single, ['crush', 'esami']);
      expect(spots.spots.single.status, SpotStatus.published);
      expect(find.text('Spot pubblicato'), findsOneWidget);
      // Siamo tornati sul canale: lo spot c'è, con i suoi tag.
      expect(find.text('Ombrello perso'), findsOneWidget);
      expect(find.text('Crush'), findsOneWidget);
      expect(find.text('Esami'), findsOneWidget);
    });

    testWidgets('errore nel caricare i tag: Riprova', (tester) async {
      final tags = FakeTagsRepository()..error = const NetworkFailure();
      await openForm(tester, FakeSpotsRepository(), owner: true, tags: tags);

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.text('Riprova'), findsOneWidget);

      tags.error = null;
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsNWidgets(fakeTags.length));
    });
  });
}
