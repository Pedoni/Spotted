import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeProfileRepository profile;

  Future<void> openEditor(
    WidgetTester tester, {
    FakeProfileRepository? repository,
  }) async {
    profile = repository ?? FakeProfileRepository();
    await pumpApp(tester, profile: profile, screenSize: tallScreen);
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifica i miei dati'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
    await tester.pumpAndSettle();
  }

  testWidgets('la voce del Profilo è attiva e apre il modulo', (tester) async {
    await openEditor(tester);

    expect(find.text('Modifica i miei dati'), findsWidgets);
    expect(find.textContaining('li vedi solo tu'), findsOneWidget);
  });

  testWidgets('parte dai dati di adesso', (tester) async {
    await openEditor(tester);

    expect(
      tester.widget<TextFormField>(field('Nome')).controller!.text,
      'Mario',
    );
    expect(
      tester.widget<TextFormField>(field('Cognome')).controller!.text,
      'Rossi',
    );
    expect(
      tester
          .widget<TextFormField>(field('Data di nascita (facoltativa)'))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('lo username si vede ma non si cambia', (tester) async {
    await openEditor(tester);

    final username = tester.widget<TextFormField>(field('Username'));
    expect(username.enabled, isFalse);
    expect(username.initialValue, 'mario_88');
  });

  testWidgets('salva nome e cognome e torna al Profilo con i dati nuovi', (
    tester,
  ) async {
    await openEditor(tester);

    await tester.enterText(field('Nome'), '  Luigi ');
    await tester.enterText(field('Cognome'), 'Bianchi');
    await save(tester);

    final call = profile.updateCalls.single;
    expect(call.firstName, 'Luigi');
    expect(call.lastName, 'Bianchi');
    expect(call.birthDate, isNull);
    expect(find.text('Dati aggiornati'), findsOneWidget);
    // Siamo di nuovo nel Profilo, con il nome nuovo.
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Luigi Bianchi'), findsOneWidget);
    expect(find.text('@mario_88'), findsOneWidget);
  });

  testWidgets('nome o cognome vuoti non partono', (tester) async {
    await openEditor(tester);

    await tester.enterText(field('Nome'), '   ');
    await tester.enterText(field('Cognome'), '');
    await save(tester);

    expect(find.text('Campo obbligatorio'), findsNWidgets(2));
    expect(profile.updateCalls, isEmpty);
  });

  group('data di nascita', () {
    Future<void> pickDate(WidgetTester tester) async {
      await tester.tap(field('Data di nascita (facoltativa)'));
      await tester.pumpAndSettle();
    }

    testWidgets('si sceglie dal selettore e si salva', (tester) async {
      await openEditor(tester);

      await pickDate(tester);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final text = tester
          .widget<TextFormField>(field('Data di nascita (facoltativa)'))
          .controller!
          .text;
      expect(text, isNotEmpty);

      await save(tester);

      final chosen = profile.updateCalls.single.birthDate;
      expect(chosen, isNotNull);
      // Un giorno intero, senza ora.
      expect(chosen!.hour, 0);
      expect(chosen.isAfter(DateTime.now()), isFalse);
    });

    testWidgets('annullando il selettore non cambia niente', (tester) async {
      await openEditor(tester);

      await pickDate(tester);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextFormField>(field('Data di nascita (facoltativa)'))
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('una data già indicata si mostra e si può togliere', (
      tester,
    ) async {
      await openEditor(
        tester,
        repository: FakeProfileRepository(
          profile: Profile(
            id: '1',
            username: 'mario_88',
            firstName: 'Mario',
            lastName: 'Rossi',
            birthDate: DateTime(1990, 12, 25),
          ),
        ),
      );
      expect(
        tester
            .widget<TextFormField>(field('Data di nascita (facoltativa)'))
            .controller!
            .text,
        isNotEmpty,
      );

      await tester.tap(find.byTooltip('Togli la data'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(field('Data di nascita (facoltativa)'))
            .controller!
            .text,
        isEmpty,
      );
      await save(tester);

      expect(profile.updateCalls.single.birthDate, isNull);
    });

    testWidgets('senza data il modulo si salva lo stesso', (tester) async {
      await openEditor(tester);

      await save(tester);

      expect(profile.updateCalls.single.birthDate, isNull);
    });
  });

  testWidgets('errore: messaggio e si resta nel modulo', (tester) async {
    await openEditor(tester);
    profile.updateError = const NetworkFailure();

    await tester.enterText(field('Nome'), 'Luigi');
    await save(tester);

    expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
    expect(find.text('Dati aggiornati'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Salva'), findsOneWidget);

    profile.updateError = null;
    await save(tester);

    expect(find.text('Dati aggiornati'), findsOneWidget);
  });

  testWidgets('mentre salva il pulsante è fermo', (tester) async {
    await openEditor(tester);
    final gate = Completer<void>();
    profile.updateGate = gate;

    await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
    await tester.pump();

    expect(find.byType(InlineProgress), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Dati aggiornati'), findsOneWidget);
  });

  testWidgets('se il profilo non si carica: errore e Riprova', (tester) async {
    await openEditor(
      tester,
      repository: FakeProfileRepository()..error = const NetworkFailure(),
    );

    expect(find.text('Problema di connessione. Riprova.'), findsWidgets);

    profile.error = null;
    await tester.tap(find.text('Riprova').last);
    await tester.pumpAndSettle();

    expect(field('Nome'), findsOneWidget);
  });
}
