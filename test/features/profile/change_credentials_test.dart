import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/widgets/inline_progress.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeAuthRepository auth;

  Future<void> openProfile(WidgetTester tester) async {
    auth = FakeAuthRepository(user: loggedInUser);
    await pumpApp(tester, auth: auth, screenSize: tallScreen);
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> submit(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  group('cambia password', () {
    Future<void> openPage(WidgetTester tester) async {
      await openProfile(tester);
      await tester.tap(find.text('Cambia password'));
      await tester.pumpAndSettle();
    }

    Future<void> fill(
      WidgetTester tester, {
      String current = 'vecchiapassword',
      String next = 'nuovapassword',
      String? confirm,
    }) async {
      await tester.enterText(field('Password attuale'), current);
      await tester.enterText(field('Nuova password'), next);
      await tester.enterText(
        field('Ripeti la nuova password'),
        confirm ?? next,
      );
    }

    testWidgets('la voce del Profilo è attiva e apre la pagina', (
      tester,
    ) async {
      await openPage(tester);

      expect(
        find.text('Per sicurezza ti chiediamo la password attuale.'),
        findsOneWidget,
      );
      expect(field('Password attuale'), findsOneWidget);
      expect(field('Nuova password'), findsOneWidget);
      expect(field('Ripeti la nuova password'), findsOneWidget);
    });

    testWidgets('cambia la password e torna al Profilo', (tester) async {
      await openPage(tester);

      await fill(tester);
      await submit(tester, 'Cambia password');

      expect(auth.passwordChanges.single, (
        current: 'vecchiapassword',
        next: 'nuovapassword',
      ));
      expect(find.text('Password cambiata'), findsOneWidget);
      // Siamo di nuovo nel Profilo.
      expect(find.text('Tema'), findsOneWidget);
      expect(find.text('Ripeti la nuova password'), findsNothing);
    });

    testWidgets('i campi vuoti non partono', (tester) async {
      await openPage(tester);

      await submit(tester, 'Cambia password');

      expect(find.text('Scrivi la password attuale'), findsOneWidget);
      expect(find.text('Almeno 8 caratteri'), findsOneWidget);
      expect(auth.passwordChanges, isEmpty);
    });

    testWidgets('la nuova password troppo corta non parte', (tester) async {
      await openPage(tester);

      await fill(tester, next: 'corta');
      await submit(tester, 'Cambia password');

      expect(find.text('Almeno 8 caratteri'), findsOneWidget);
      expect(auth.passwordChanges, isEmpty);
    });

    testWidgets('la nuova password uguale all attuale non parte', (
      tester,
    ) async {
      await openPage(tester);

      await fill(tester, next: 'vecchiapassword');
      await submit(tester, 'Cambia password');

      expect(
        find.text('Deve essere diversa dalla password attuale'),
        findsOneWidget,
      );
      expect(auth.passwordChanges, isEmpty);
    });

    testWidgets('le due nuove password devono coincidere', (tester) async {
      await openPage(tester);

      await fill(tester, confirm: 'diversapassword');
      await submit(tester, 'Cambia password');

      expect(find.text('Le due password non coincidono'), findsOneWidget);
      expect(auth.passwordChanges, isEmpty);
    });

    testWidgets('password attuale sbagliata: lo dice e si resta qui', (
      tester,
    ) async {
      await openPage(tester);

      await fill(tester, current: 'sbagliata123');
      await submit(tester, 'Cambia password');

      expect(find.text('La password attuale non è corretta'), findsOneWidget);
      expect(find.text('Password cambiata'), findsNothing);
      expect(find.text('Ripeti la nuova password'), findsOneWidget);
      // La password non è cambiata.
      expect(auth.password, 'vecchiapassword');
    });

    testWidgets('errore di rete: messaggio e si può riprovare', (tester) async {
      await openPage(tester);
      auth.changeError = const NetworkFailure();

      await fill(tester);
      await submit(tester, 'Cambia password');

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      auth.changeError = null;
      await submit(tester, 'Cambia password');

      expect(find.text('Password cambiata'), findsOneWidget);
    });

    testWidgets('mentre invia il pulsante è fermo e mostra l avanzamento', (
      tester,
    ) async {
      await openPage(tester);
      final gate = Completer<void>();
      auth.changeGate = gate;
      await fill(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Cambia password'));
      await tester.pump();

      expect(find.byType(InlineProgress), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Password cambiata'), findsOneWidget);
    });
  });

  group('cambia email', () {
    Future<void> openPage(WidgetTester tester) async {
      await openProfile(tester);
      await tester.tap(find.text('Cambia email'));
      await tester.pumpAndSettle();
    }

    Future<void> fill(
      WidgetTester tester, {
      String email = 'nuova@b.it',
      String password = 'vecchiapassword',
    }) async {
      await tester.enterText(field('Nuova email'), email);
      await tester.enterText(field('Password attuale'), password);
    }

    testWidgets('la voce del Profilo è attiva e apre la pagina', (
      tester,
    ) async {
      await openPage(tester);

      expect(
        find.textContaining('Ti scriviamo per confermare'),
        findsOneWidget,
      );
      expect(field('Nuova email'), findsOneWidget);
      expect(field('Password attuale'), findsOneWidget);
    });

    testWidgets('chiede il cambio, dice di controllare la posta e torna', (
      tester,
    ) async {
      await openPage(tester);

      await fill(tester, email: '  nuova@b.it ');
      await submit(tester, 'Invia la conferma');

      expect(auth.emailChanges.single, (
        current: 'vecchiapassword',
        email: 'nuova@b.it',
      ));
      expect(
        find.text(
          'Ti abbiamo scritto a nuova@b.it: apri il messaggio per confermare '
          'il nuovo indirizzo.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tema'), findsOneWidget);
    });

    testWidgets('nel Profilo resta la vecchia email, con quella in attesa', (
      tester,
    ) async {
      await openPage(tester);

      await fill(tester);
      await submit(tester, 'Invia la conferma');

      // L'indirizzo valido è ancora quello di prima.
      expect(find.text('a@b.it'), findsOneWidget);
      expect(find.text('In attesa di conferma: nuova@b.it'), findsOneWidget);
    });

    testWidgets('senza cambio in corso non c è la nota', (tester) async {
      await openProfile(tester);

      expect(find.textContaining('In attesa di conferma'), findsNothing);
    });

    testWidgets('un indirizzo non valido non parte', (tester) async {
      await openPage(tester);

      await fill(tester, email: 'non-una-email');
      await submit(tester, 'Invia la conferma');

      expect(find.text("Inserisci un'email valida"), findsOneWidget);
      expect(auth.emailChanges, isEmpty);
    });

    testWidgets('l indirizzo di adesso non parte', (tester) async {
      await openPage(tester);

      await fill(tester, email: 'A@b.it');
      await submit(tester, 'Invia la conferma');

      expect(find.text('È già la tua email'), findsOneWidget);
      expect(auth.emailChanges, isEmpty);
    });

    testWidgets('la password vuota non parte', (tester) async {
      await openPage(tester);

      await fill(tester, password: '');
      await submit(tester, 'Invia la conferma');

      expect(find.text('Scrivi la password attuale'), findsOneWidget);
      expect(auth.emailChanges, isEmpty);
    });

    testWidgets('password sbagliata: lo dice e non cambia niente', (
      tester,
    ) async {
      await openPage(tester);

      await fill(tester, password: 'sbagliata123');
      await submit(tester, 'Invia la conferma');

      expect(find.text('La password attuale non è corretta'), findsOneWidget);
      expect(auth.user?.pendingEmail, isNull);
    });

    testWidgets('indirizzo già usato: messaggio e si resta qui', (
      tester,
    ) async {
      await openPage(tester);
      auth.changeError = const AuthFailure(AuthFailureReason.emailTaken);

      await fill(tester);
      await submit(tester, 'Invia la conferma');

      expect(
        find.text('Esiste già un account con questa email'),
        findsOneWidget,
      );
      expect(find.text('Nuova email'), findsOneWidget);
    });
  });
}
