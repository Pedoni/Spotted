import 'package:flutter/material.dart';

/// Data e ora locali di un momento, come "31 dic 2025 · 14:30": la data nel
/// formato breve della lingua e l'ora a 24 ore. Gli orari arrivano dal server
/// in UTC e si mostrano sempre nel fuso del dispositivo.
String formatDateTime(BuildContext context, DateTime value) {
  final localizations = MaterialLocalizations.of(context);
  final local = value.toLocal();
  final date = localizations.formatShortDate(local);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: true,
  );
  return '$date · $time';
}

/// L'ora locale di un momento, a 24 ore ("14:30").
String formatTime(BuildContext context, DateTime value) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(value.toLocal()),
    alwaysUse24HourFormat: true,
  );
}

/// Da quando a quando dura qualcosa. Senza fine è solo l'inizio
/// ("31 dic 2025 · 14:30"); se finisce lo stesso giorno aggiunge l'ora di fine
/// ("31 dic 2025 · 14:30 – 16:00"); altrimenti scrive entrambe le date.
String formatDateTimeRange(
  BuildContext context,
  DateTime start,
  DateTime? end,
) {
  final from = formatDateTime(context, start);
  if (end == null) return from;
  final s = start.toLocal();
  final e = end.toLocal();
  final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
  return sameDay
      ? '$from – ${formatTime(context, end)}'
      : '$from – ${formatDateTime(context, end)}';
}
