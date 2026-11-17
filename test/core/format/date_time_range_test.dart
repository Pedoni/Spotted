import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/l10n/app_localizations.dart';

void main() {
  Future<String> format(
    WidgetTester tester,
    DateTime start,
    DateTime? end,
  ) async {
    late String result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            result = formatDateTimeRange(context, start, end);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('senza fine è solo l inizio', (tester) async {
    final text = await format(tester, DateTime(2031, 3, 14, 18, 30), null);

    expect(text, endsWith('· 18:30'));
    expect(text, isNot(contains('–')));
  });

  testWidgets('se finisce lo stesso giorno aggiunge solo l ora di fine', (
    tester,
  ) async {
    final text = await format(
      tester,
      DateTime(2031, 3, 14, 18, 30),
      DateTime(2031, 3, 14, 20),
    );

    expect(text, endsWith('· 18:30 – 20:00'));
  });

  testWidgets('se finisce un altro giorno scrive entrambe le date', (
    tester,
  ) async {
    final text = await format(
      tester,
      DateTime(2031, 3, 14, 22),
      DateTime(2031, 3, 15, 2),
    );

    final parts = text.split(' – ');
    expect(parts, hasLength(2));
    expect(parts.first, endsWith('· 22:00'));
    expect(parts.last, endsWith('· 02:00'));
    expect(parts.last, isNot(parts.first));
  });

  testWidgets('l ora è sempre a 24 ore', (tester) async {
    final text = await format(
      tester,
      DateTime(2031, 3, 14, 15),
      DateTime(2031, 3, 14, 23, 5),
    );

    expect(text, contains('15:00'));
    expect(text, contains('23:05'));
    expect(text, isNot(contains('PM')));
  });
}
