import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/widgets/inline_progress.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> openSignUp(WidgetTester tester, FakeAuthRepository repo) async {
    await pumpApp(tester, auth: repo);
    await tester.tap(find.text('Non hai un account? Registrati'));
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String username = 'Mario_88',
  }) async {
    await tester.enterText(field('Nome'), 'Mario');
    await tester.enterText(field('Cognome'), 'Rossi');
    await tester.enterText(field('Username'), username);
    await tester.enterText(field('Email'), 'mario@b.it');
    await tester.enterText(field('Password'), '12345678');
  }

  testWidgets('valida i campi', (tester) async {
    final repo = FakeAuthRepository();
    await openSignUp(tester, repo);

    await tester.enterText(field('Username'), 'a!');
    await tester.enterText(field('Password'), 'corta');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Campo obbligatorio'), findsNWidgets(2));
    expect(
      find.text('3-30 caratteri: lettere, numeri e underscore'),
      findsOneWidget,
    );
    expect(find.text('Almeno 8 caratteri'), findsOneWidget);
    expect(repo.signUpCalls, isEmpty);
  });

  testWidgets('registrazione riuscita: username normalizzato e home', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await openSignUp(tester, repo);

    await fillForm(tester);
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(repo.signUpCalls.single['username'], 'mario_88');
    expect(repo.signUpCalls.single['firstName'], 'Mario');
    expect(
      find.text('Non hai ancora pubblicato spot'),
      findsOneWidget,
    );
  });

  testWidgets('username occupato mostra l errore', (tester) async {
    final repo = FakeAuthRepository()..takenUsernames = {'mario_88'};
    await openSignUp(tester, repo);

    await fillForm(tester);
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Questo username è già in uso'), findsOneWidget);
    expect(repo.signUpCalls, isEmpty);
  });

  group('controllo dello username mentre si scrive', () {
    const wait = Duration(milliseconds: 600);

    Future<void> typeUsername(WidgetTester tester, String value) async {
      await tester.enterText(field('Username'), value);
      await tester.pump(wait);
      // Il tempo di far finire la dissolvenza dell'avviso.
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('libero: dice che è disponibile, controllato in minuscolo', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      await openSignUp(tester, repo);

      await typeUsername(tester, 'Mario_88');

      expect(find.text('Username disponibile'), findsOneWidget);
      expect(find.text('Questo username è già in uso'), findsNothing);
      expect(repo.availabilityCalls, ['mario_88']);
    });

    testWidgets('occupato: lo dice subito e non si può registrare', (
      tester,
    ) async {
      final repo = FakeAuthRepository()..takenUsernames = {'mario_88'};
      await openSignUp(tester, repo);

      await typeUsername(tester, 'mario_88');

      expect(find.text('Questo username è già in uso'), findsOneWidget);
      expect(find.text('Username disponibile'), findsNothing);

      await fillForm(tester);
      await tester.pump(wait);
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(repo.signUpCalls, isEmpty);
      expect(find.text('Questo username è già in uso'), findsWidgets);
    });

    testWidgets('cambiando username l avviso sparisce', (tester) async {
      final repo = FakeAuthRepository()..takenUsernames = {'mario_88'};
      await openSignUp(tester, repo);
      await typeUsername(tester, 'mario_88');
      expect(find.text('Questo username è già in uso'), findsOneWidget);

      await typeUsername(tester, 'mario_89');

      expect(find.text('Questo username è già in uso'), findsNothing);
      expect(find.text('Username disponibile'), findsOneWidget);
    });

    testWidgets('uno username non valido non viene cercato', (tester) async {
      final repo = FakeAuthRepository();
      await openSignUp(tester, repo);

      await typeUsername(tester, 'a!');
      await typeUsername(tester, 'ab');

      expect(repo.availabilityCalls, isEmpty);
      expect(find.text('Username disponibile'), findsNothing);
    });

    testWidgets('aspetta che si smetta di scrivere prima di cercare', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      await openSignUp(tester, repo);

      await tester.enterText(field('Username'), 'mar');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(field('Username'), 'mari');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(field('Username'), 'mario');
      expect(repo.availabilityCalls, isEmpty);

      await tester.pump(wait);

      expect(repo.availabilityCalls, ['mario']);
    });

    testWidgets('mentre controlla mostra l avanzamento', (tester) async {
      final repo = FakeAuthRepository()..availabilityGate = Completer<void>();
      await openSignUp(tester, repo);

      await typeUsername(tester, 'mario_88');

      expect(find.byType(InlineProgress), findsOneWidget);
      repo.availabilityGate!.complete();
      await tester.pump();

      expect(find.byType(InlineProgress), findsNothing);
      expect(find.text('Username disponibile'), findsOneWidget);
    });

    testWidgets('una risposta in ritardo non vale se il testo è cambiato', (
      tester,
    ) async {
      final repo = FakeAuthRepository()
        ..takenUsernames = {'mario_88'}
        ..availabilityGate = Completer<void>();
      await openSignUp(tester, repo);

      await typeUsername(tester, 'mario_88');
      // Nel frattempo si scrive un altro username (non ancora controllato).
      await tester.enterText(field('Username'), 'mario_8');
      repo.availabilityGate!.complete();
      await tester.pump();

      expect(find.text('Questo username è già in uso'), findsNothing);
    });

    testWidgets('senza rete non dice niente e si può comunque registrare', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      await openSignUp(tester, repo);
      repo.availabilityError = const NetworkFailure();

      await typeUsername(tester, 'mario_88');

      expect(find.text('Username disponibile'), findsNothing);
      expect(find.text('Questo username è già in uso'), findsNothing);

      repo.availabilityError = null;
      await fillForm(tester);
      await tester.pump(wait);
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(repo.signUpCalls, hasLength(1));
    });
  });
}
