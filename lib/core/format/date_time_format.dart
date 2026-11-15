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
