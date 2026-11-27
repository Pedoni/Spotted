import 'package:flutter/material.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/features/admin/domain/entities/admin_action.dart';
import 'package:spotted/features/admin/domain/entities/admin_report.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/presentation/widgets/report_dialog.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Una segnalazione per l'admin: il canale, il motivo, i dettagli, il testo
/// segnalato (con il numero di segnalazioni sullo stesso contenuto) e le
/// azioni.
class AdminReportCard extends StatelessWidget {
  const AdminReportCard({
    required this.report,
    required this.onAct,
    this.busy = false,
    super.key,
  });

  final AdminReport report;
  final void Function(AdminAction action) onAct;

  /// Un'azione su questa segnalazione è in corso: i pulsanti sono fermi.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isComment = report.kind == ReportKind.comment;
    final date = formatDateTime(context, report.createdAt);
    final callback = busy ? null : onAct;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${report.channelName} · '
              '${isComment ? l10n.reportOnComment : l10n.reportOnSpot} · $date',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text(reportReasonLabel(l10n, report.reason))),
                if (report.reportCount > 1)
                  Chip(label: Text(l10n.reportCount(report.reportCount))),
                if (report.contentHidden)
                  Chip(label: Text(l10n.adminAlreadyHidden)),
              ],
            ),
            if (report.details != null) ...[
              const SizedBox(height: 8),
              Text(report.details!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Text(report.spotTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(report.content),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: callback == null
                      ? null
                      : () => onAct(AdminAction.dismiss),
                  child: Text(l10n.reportDismiss),
                ),
                TextButton(
                  onPressed: callback == null
                      ? null
                      : () => onAct(AdminAction.resolve),
                  child: Text(l10n.reportResolve),
                ),
                if (!report.contentHidden)
                  TextButton(
                    onPressed: callback == null
                        ? null
                        : () => onAct(AdminAction.hide),
                    child: Text(l10n.adminHide),
                  ),
                if (!isComment)
                  TextButton(
                    onPressed: callback == null
                        ? null
                        : () => onAct(AdminAction.remove),
                    child: Text(l10n.adminRemove),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
