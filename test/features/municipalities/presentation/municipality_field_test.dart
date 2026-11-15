import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/features/municipalities/presentation/providers/municipalities_providers.dart';
import 'package:spotted/features/municipalities/presentation/widgets/municipality_field.dart';
import 'package:spotted/l10n/app_localizations.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeMunicipalitiesRepository repository;
  late GlobalKey<FormState> formKey;
  MunicipalityChoice? changed;
  var changes = 0;

  setUp(() {
    repository = FakeMunicipalitiesRepository(
      municipalities: [
        makeMunicipality(),
        makeMunicipality(
          code: '050027',
          name: 'Pistoia',
          provinceCode: 'PT',
          provinceName: 'Pistoia',
        ),
        makeMunicipality(
          code: '008888',
          name: 'Forlì',
          provinceCode: 'FC',
          provinceName: 'Forlì-Cesena',
          regionName: 'Emilia-Romagna',
        ),
        makeMunicipality(
          code: '013123',
          name: 'Livo',
          provinceCode: 'CO',
          provinceName: 'Como',
          regionName: 'Lombardia',
        ),
        makeMunicipality(
          code: '022121',
          name: 'Livo',
          provinceCode: 'TN',
          provinceName: 'Trento',
          regionName: 'Trentino-Alto Adige/Südtirol',
        ),
      ],
    );
    formKey = GlobalKey<FormState>();
    changed = null;
    changes = 0;
  });

  Future<void> pumpField(
    WidgetTester tester, {
    MunicipalityChoice? initialValue,
    String? labelText,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [
          municipalitiesRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: MunicipalityField(
                  initialValue: initialValue,
                  labelText: labelText,
                  onChanged: (choice) {
                    changed = choice;
                    changes++;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final field = find.byType(TextFormField);

  /// Scrive [text] e aspetta che la ricerca (con la sua attesa) finisca.
  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(field, text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextFormField>(field).controller!.text;

  group('facoltativo', () {
    testWidgets('vuoto è valido', (tester) async {
      await pumpField(tester);

      expect(formKey.currentState!.validate(), isTrue);
      expect(changes, 0);
    });

    testWidgets("l'etichetta dice che è facoltativo", (tester) async {
      await pumpField(tester);

      expect(find.text('Comune (facoltativo)'), findsOneWidget);
    });

    testWidgets("l'etichetta si può cambiare", (tester) async {
      await pumpField(tester, labelText: 'Dove');

      expect(find.text('Dove'), findsOneWidget);
    });
  });

  group('ricerca', () {
    testWidgets('con una sola lettera non cerca e non suggerisce', (
      tester,
    ) async {
      await pumpField(tester);

      await type(tester, 'p');

      expect(repository.searchCalls, isEmpty);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('da 2 lettere suggerisce, prima i nomi che iniziano così', (
      tester,
    ) async {
      await pumpField(tester);

      await type(tester, 'pi');

      expect(repository.searchCalls.single.query, 'pi');
      expect(find.text('Pisa'), findsOneWidget);
      expect(find.text('Pistoia'), findsOneWidget);
      // Di ogni suggerimento si vedono provincia, regione e sigla.
      expect(find.text('Pisa · Toscana'), findsOneWidget);
      expect(find.text('PI'), findsOneWidget);
      expect(find.text('PT'), findsOneWidget);
    });

    testWidgets('non distingue accenti e maiuscole', (tester) async {
      await pumpField(tester);

      await type(tester, 'FORLI');

      expect(find.text('Forlì'), findsOneWidget);
    });

    testWidgets('aspetta che si smetta di scrivere prima di cercare', (
      tester,
    ) async {
      await pumpField(tester);

      await tester.enterText(field, 'pi');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, 'pis');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, 'pist');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Una sola richiesta, per il testo finale.
      expect(repository.searchCalls.map((c) => c.query), ['pist']);
      expect(find.text('Pistoia'), findsOneWidget);
      expect(find.text('Pisa'), findsNothing);
    });

    testWidgets('nessun risultato: lo dice', (tester) async {
      await pumpField(tester);

      await type(tester, 'zzz');

      expect(find.text('Nessun comune trovato'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('errore nella ricerca: messaggio e nessun suggerimento', (
      tester,
    ) async {
      repository.searchError = const NetworkFailure();
      await pumpField(tester);

      await type(tester, 'pis');

      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('il messaggio di errore sparisce quando si riscrive', (
      tester,
    ) async {
      repository.searchError = const NetworkFailure();
      await pumpField(tester);
      await type(tester, 'pis');
      expect(find.text('Problema di connessione. Riprova.'), findsOneWidget);

      repository.searchError = null;
      await type(tester, 'pisa');

      expect(find.text('Problema di connessione. Riprova.'), findsNothing);
      expect(find.text('Pisa'), findsOneWidget);
    });

    testWidgets('togliendo il testo scompaiono i messaggi', (tester) async {
      await pumpField(tester);
      await type(tester, 'zzz');
      expect(find.text('Nessun comune trovato'), findsOneWidget);

      await type(tester, '');

      expect(find.text('Nessun comune trovato'), findsNothing);
    });
  });

  group('scelta', () {
    testWidgets('scegliendo un suggerimento il campo mostra nome e sigla', (
      tester,
    ) async {
      await pumpField(tester);
      await type(tester, 'pis');

      await tester.tap(find.text('Pisa'));
      await tester.pumpAndSettle();

      expect(fieldText(tester), 'Pisa (PI)');
      expect(
        changed,
        const MunicipalityChoice(
          istatCode: '050026',
          label: 'Pisa (PI)',
          provinceCode: 'PI',
          provinceName: 'Pisa',
          regionName: 'Toscana',
        ),
      );
      expect(changes, 1);
      // Il suggerimento si chiude e il campo è valido.
      expect(find.byType(ListTile), findsNothing);
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('due comuni omonimi si scelgono dalla provincia', (
      tester,
    ) async {
      await pumpField(tester);
      await type(tester, 'livo');
      expect(find.text('Livo'), findsNWidgets(2));

      await tester.tap(find.text('Trento · Trentino-Alto Adige/Südtirol'));
      await tester.pumpAndSettle();

      expect(fieldText(tester), 'Livo (TN)');
      expect(changed!.istatCode, '022121');
    });

    testWidgets('dopo la scelta non si cerca di nuovo il testo scelto', (
      tester,
    ) async {
      await pumpField(tester);
      await type(tester, 'pis');
      await tester.tap(find.text('Pisa'));
      await tester.pumpAndSettle();
      final calls = repository.searchCalls.length;

      await tester.pump(const Duration(milliseconds: 500));

      expect(repository.searchCalls, hasLength(calls));
    });

    testWidgets('il comune iniziale è mostrato ed è valido', (tester) async {
      await pumpField(
        tester,
        initialValue: const MunicipalityChoice(
          istatCode: '050026',
          label: 'Pisa (PI)',
        ),
      );

      expect(fieldText(tester), 'Pisa (PI)');
      expect(formKey.currentState!.validate(), isTrue);
    });
  });

  group('niente testo libero', () {
    testWidgets('un testo scritto e non scelto non è valido', (tester) async {
      await pumpField(tester);
      await type(tester, 'Città inventata');

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text("Scegli un comune dall'elenco"), findsOneWidget);
      expect(changed, isNull);
    });

    testWidgets('anche un testo uguale a un comune, se non è scelto', (
      tester,
    ) async {
      await pumpField(tester);
      await type(tester, 'Pisa');

      // Scritto per intero, ma non scelto dall'elenco: non vale.
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('dopo la scelta, modificare il testo annulla la scelta', (
      tester,
    ) async {
      await pumpField(tester);
      await type(tester, 'pis');
      await tester.tap(find.text('Pisa'));
      await tester.pumpAndSettle();
      expect(changed, isNotNull);

      await tester.enterText(field, 'Pisa (PI) x');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(changed, isNull);
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('lo spazio da solo non conta come testo', (tester) async {
      await pumpField(tester);
      await tester.enterText(field, '   ');
      await tester.pump(const Duration(milliseconds: 400));

      expect(formKey.currentState!.validate(), isTrue);
      expect(repository.searchCalls, isEmpty);
    });
  });

  group('togliere il comune', () {
    testWidgets('la x non c è finché il campo è vuoto', (tester) async {
      await pumpField(tester);

      expect(find.byTooltip('Togli il comune'), findsNothing);

      await tester.enterText(field, 'pi');
      await tester.pump();

      expect(find.byTooltip('Togli il comune'), findsOneWidget);
      // Fa scadere l'attesa prima di cercare.
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('la x svuota il campo e annulla la scelta', (tester) async {
      await pumpField(tester);
      await type(tester, 'pis');
      await tester.tap(find.text('Pisa'));
      await tester.pumpAndSettle();
      expect(changed, isNotNull);

      await tester.tap(find.byTooltip('Togli il comune'));
      await tester.pumpAndSettle();

      expect(fieldText(tester), isEmpty);
      expect(changed, isNull);
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.byTooltip('Togli il comune'), findsNothing);
    });

    testWidgets('la x toglie anche un testo non scelto, senza avvisare', (
      tester,
    ) async {
      await pumpField(tester);
      await tester.enterText(field, 'Cit');
      await tester.pump();

      await tester.tap(find.byTooltip('Togli il comune'));
      await tester.pumpAndSettle();

      expect(fieldText(tester), isEmpty);
      // Non c'era una scelta da annullare.
      expect(changes, 0);
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('dopo aver tolto si può scegliere un altro comune', (
      tester,
    ) async {
      await pumpField(
        tester,
        initialValue: const MunicipalityChoice(
          istatCode: '050026',
          label: 'Pisa (PI)',
        ),
      );

      await tester.tap(find.byTooltip('Togli il comune'));
      await tester.pumpAndSettle();
      await type(tester, 'pist');
      await tester.tap(find.text('Pistoia'));
      await tester.pumpAndSettle();

      expect(fieldText(tester), 'Pistoia (PT)');
      expect(changed!.istatCode, '050027');
    });
  });
}
