import 'package:flutter/material.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';
import 'package:spotted/features/reports/domain/report_validators.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Motivo e dettagli scelti dall'utente.
typedef ReportDraft = ({ReportReason reason, String? details});

/// Il testo di un [ReportReason].
String reportReasonLabel(AppLocalizations l10n, ReportReason reason) {
  return switch (reason) {
    ReportReason.spam => l10n.reportReasonSpam,
    ReportReason.offensive => l10n.reportReasonOffensive,
    ReportReason.hate => l10n.reportReasonHate,
    ReportReason.other => l10n.reportReasonOther,
  };
}

/// Chiede il motivo (obbligatorio) e dei dettagli (facoltativi). Restituisce
/// `null` se l'utente annulla.
Future<ReportDraft?> showReportDialog(BuildContext context) {
  return showDialog<ReportDraft>(
    context: context,
    builder: (context) => const _ReportDialog(),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _details = TextEditingController();
  ReportReason? _reason;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.reportTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final reason in ReportReason.values)
                  ChoiceChip(
                    label: Text(reportReasonLabel(l10n, reason)),
                    selected: _reason == reason,
                    onSelected: (_) => setState(() => _reason = reason),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _details,
              maxLines: 3,
              maxLength: ReportValidators.maxDetailsLength,
              decoration: InputDecoration(labelText: l10n.reportDetailsLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _reason == null
              ? null
              : () => Navigator.of(context).pop((
                  reason: _reason!,
                  details: _details.text,
                )),
          child: Text(l10n.reportSend),
        ),
      ],
    );
  }
}
