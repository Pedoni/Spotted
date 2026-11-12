import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/format/date_time_format.dart';

/// Il testo prodotto da [formatDateTime] per [value] in italiano.
Future<String> format(
  WidgetTester tester,
  DateTime value, {
  bool use24HourFormat = false,
}) async {
  late String result;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('it')],
      home: MediaQuery(
        data: MediaQueryData(alwaysUse24HourFormat: use24HourFormat),
        child: Builder(
          builder: (context) {
            result = formatDateTime(context, value);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return result;
}

void main() {
  testWidgets('data breve e ora, separate da un punto elenco', (tester) async {
    expect(
      await format(tester, DateTime(2025, 12, 31, 14, 30)),
      '31 dic 2025 · 14:30',
    );
  });

  testWidgets('le ore e i minuti hanno sempre due cifre', (tester) async {
    expect(
      await format(tester, DateTime(2026, 3, 5, 9, 5)),
      '5 mar 2026 · 09:05',
    );
  });

  testWidgets('mezzanotte è 00:00 e mezzogiorno 12:00', (tester) async {
    expect(
      await format(tester, DateTime(2026, 1, 2)),
      '2 gen 2026 · 00:00',
    );
    expect(
      await format(tester, DateTime(2026, 1, 2, 12)),
      '2 gen 2026 · 12:00',
    );
  });

  testWidgets('l ora è sempre a 24 ore, qualunque impostazione del telefono', (
    tester,
  ) async {
    final value = DateTime(2026, 6, 10, 18, 45);

    expect(await format(tester, value), '10 giu 2026 · 18:45');
    expect(
      await format(tester, value, use24HourFormat: true),
      '10 giu 2026 · 18:45',
    );
  });

  testWidgets('un orario UTC si mostra nel fuso del dispositivo', (
    tester,
  ) async {
    final utc = DateTime.utc(2026, 1, 1, 10, 20);
    final local = utc.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');

    final text = await format(tester, utc);

    expect(text, endsWith('· $hh:$mm'));
  });

  testWidgets('non cambia se l orario è già locale o in UTC (stesso istante)', (
    tester,
  ) async {
    final utc = DateTime.utc(2026, 5, 20, 7, 15);

    expect(await format(tester, utc), await format(tester, utc.toLocal()));
  });
}
