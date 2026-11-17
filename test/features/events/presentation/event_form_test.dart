import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/features/events/presentation/widgets/event_form.dart';
import 'package:spotted/l10n/app_localizations.dart';

void main() {
  Future<List<EventFormValues>> pumpForm(
    WidgetTester tester, {
    required bool requireFutureStart,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final submitted = <EventFormValues>[];
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventForm(
              submitLabel: 'Salva',
              requireFutureStart: requireFutureStart,
              initialTitle: 'Titolo',
              initialDescription: 'Descrizione',
              initialStartsAt: startsAt,
              initialEndsAt: endsAt,
              onSubmit: submitted.add,
            ),
          ),
        ),
      ),
    );
    return submitted;
  }

  testWidgets('creando, un inizio già passato non è valido', (tester) async {
    final submitted = await pumpForm(
      tester,
      requireFutureStart: true,
      startsAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    await tester.tap(find.text('Salva'));
    await tester.pump();

    expect(find.text("L'inizio deve essere nel futuro"), findsOneWidget);
    expect(submitted, isEmpty);
  });

  testWidgets('modificando, un inizio passato va bene', (tester) async {
    final submitted = await pumpForm(
      tester,
      requireFutureStart: false,
      startsAt: DateTime.now().subtract(const Duration(days: 3)),
    );

    await tester.tap(find.text('Salva'));
    await tester.pump();

    expect(find.text("L'inizio deve essere nel futuro"), findsNothing);
    expect(submitted, hasLength(1));
  });

  testWidgets('una fine prima dell inizio non è valida', (tester) async {
    final start = DateTime.now().add(const Duration(days: 2));
    final submitted = await pumpForm(
      tester,
      requireFutureStart: true,
      startsAt: start,
      endsAt: start.subtract(const Duration(hours: 1)),
    );

    await tester.tap(find.text('Salva'));
    await tester.pump();

    expect(
      find.text("La fine non può essere prima dell'inizio"),
      findsOneWidget,
    );
    expect(submitted, isEmpty);
  });

  testWidgets('una fine uguale all inizio va bene', (tester) async {
    final start = DateTime.now().add(const Duration(days: 2));
    final submitted = await pumpForm(
      tester,
      requireFutureStart: true,
      startsAt: start,
      endsAt: start,
    );

    await tester.tap(find.text('Salva'));
    await tester.pump();

    expect(submitted, hasLength(1));
    expect(submitted.single.endsAt, start);
  });
}
