import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Future<void> openChannels(
    WidgetTester tester,
    FakeChannelsRepository repository,
  ) async {
    await pumpApp(tester, channels: repository);
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra i canali con topic e luogo', (tester) async {
    final repo = FakeChannelsRepository(
      channels: [
        makeChannel(1, name: 'Spotted Pisa', topicId: 't-uni', place: 'Pisa'),
        makeChannel(2, name: 'Spotted Roma'),
      ],
    );
    await openChannels(tester, repo);

    expect(find.text('Spotted Pisa'), findsOneWidget);
    expect(find.text('Università · Pisa'), findsOneWidget);
    expect(find.text('Spotted Roma'), findsOneWidget);
  });

  testWidgets('lista vuota', (tester) async {
    await openChannels(tester, FakeChannelsRepository());

    expect(find.text('Nessun canale trovato'), findsOneWidget);
  });

  testWidgets('la ricerca filtra dopo il debounce', (tester) async {
    final repo = FakeChannelsRepository(
      channels: [
        makeChannel(1, name: 'Spotted Pisa'),
        makeChannel(2, name: 'Spotted Roma'),
      ],
    );
    await openChannels(tester, repo);

    await tester.enterText(find.byType(TextField), 'roma');
    await tester.pump(const Duration(milliseconds: 100));
    // Prima del debounce non parte nessuna nuova richiesta.
    expect(repo.listCalls, hasLength(1));

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Spotted Roma'), findsOneWidget);
    expect(find.text('Spotted Pisa'), findsNothing);
  });

  testWidgets('scorrendo carica la pagina successiva', (tester) async {
    final repo = FakeChannelsRepository(
      channels: List.generate(30, makeChannel),
    );
    await openChannels(tester, repo);
    expect(repo.listCalls, hasLength(1));

    await tester.drag(find.byType(ListView).last, const Offset(0, -4000));
    await tester.pumpAndSettle();

    expect(repo.listCalls.map((c) => c.offset), [0, 20]);
  });

  testWidgets('errore sulla pagina successiva: messaggio e Riprova', (
    tester,
  ) async {
    final repo = FakeChannelsRepository(
      channels: List.generate(30, makeChannel),
    );
    await openChannels(tester, repo);

    repo.listError = const NetworkFailure();
    await tester.drag(find.byType(ListView).last, const Offset(0, -4000));
    await tester.pumpAndSettle();

    expect(find.text('Impossibile caricare altri canali'), findsOneWidget);
    // Non ritenta da sola in loop.
    final calls = repo.listCalls.length;
    await tester.pump(const Duration(seconds: 1));
    expect(repo.listCalls, hasLength(calls));

    repo.listError = null;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Impossibile caricare altri canali'), findsNothing);
    expect(repo.listCalls.last.offset, 20);
  });

  testWidgets('errore: messaggio e Riprova', (tester) async {
    final repo = FakeChannelsRepository()..listError = const NetworkFailure();
    await openChannels(tester, repo);

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

    repo
      ..listError = null
      ..channels = [makeChannel(1, name: 'Spotted Pisa')];
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Spotted Pisa'), findsOneWidget);
  });

  testWidgets('toccando un canale si apre il dettaglio', (tester) async {
    final repo = FakeChannelsRepository(
      channels: [
        makeChannel(
          1,
          name: 'Spotted Pisa',
          topicId: 't-uni',
          place: 'Pisa',
          description: 'Il canale di Pisa',
        ),
      ],
    );
    await openChannels(tester, repo);

    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();

    expect(find.text('Il canale di Pisa'), findsOneWidget);
    expect(find.text('Università'), findsOneWidget);
    expect(find.text('Ancora nessuno spot. Scrivi il primo!'), findsOneWidget);
  });
}
