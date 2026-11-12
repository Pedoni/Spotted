import 'package:flutter/material.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/features/reports/domain/entities/channel_report.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_resolution.dart';
import 'package:spotted/features/reports/presentation/widgets/report_dialog.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Una segnalazione aperta: motivo, dettagli, testo segnalato e le azioni per
/// chiuderla.
class ReportCard extends StatelessWidget {
  const ReportCard({
    required this.report,
    required this.onOpen,
    required this.onResolve,
    super.key,
  });

  final ChannelReport report;
  final VoidCallback onOpen;
  final void Function(ReportResolution resolution) onResolve;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = formatDateTime(context, report.createdAt);
    final isComment = report.kind == ReportKind.comment;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${isComment ? l10n.reportOnComment : l10n.reportOnSpot}'
                ' · $date',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Chip(label: Text(reportReasonLabel(l10n, report.reason))),
              if (report.details != null) ...[
                const SizedBox(height: 8),
                Text(report.details!, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 8),
              Text(report.spotTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(report.content),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onResolve(ReportResolution.dismissed),
                    child: Text(l10n.reportDismiss),
                  ),
                  TextButton(
                    onPressed: () => onResolve(ReportResolution.resolved),
                    child: Text(l10n.reportResolve),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
