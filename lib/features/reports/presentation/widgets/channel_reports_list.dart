import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/reports/domain/entities/channel_report.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_resolution.dart';
import 'package:spotted/features/reports/presentation/providers/channel_reports_feed.dart';
import 'package:spotted/features/reports/presentation/widgets/report_dialog.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Le segnalazioni aperte di un canale, da chiudere. Solo per il proprietario.
class ChannelReportsList extends ConsumerWidget {
  const ChannelReportsList({required this.channelId, super.key});

  final String channelId;

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    ChannelReport report,
    ReportResolution resolution,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(channelReportsFeedProvider(channelId).notifier)
          .resolve(report.id, resolution);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            resolution == ReportResolution.resolved
                ? l10n.reportResolved
                : l10n.reportDismissed,
          ),
        ),
      );
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = channelReportsFeedProvider(channelId);
    final feed = ref.watch(provider);

    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
      data: (paged) {
        if (paged.items.isEmpty) {
          return Center(child: Text(l10n.noReports));
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future),
          child: ListView.builder(
            itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < paged.items.length) {
                final report = paged.items[index];
                return _ReportCard(
                  report: report,
                  onOpen: () => context.push(AppRoutes.spotPath(report.spotId)),
                  onResolve: (resolution) =>
                      unawaited(_resolve(context, ref, report, resolution)),
                );
              }
              if (paged.loadMoreFailed) {
                return ListTile(
                  title: Text(l10n.loadMoreReportsError),
                  trailing: TextButton(
                    onPressed: () =>
                        unawaited(ref.read(provider.notifier).loadMore()),
                    child: Text(l10n.retry),
                  ),
                );
              }
              // L'ultimo elemento è il caricamento: quando compare a schermo
              // si chiede la pagina successiva.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  unawaited(ref.read(provider.notifier).loadMore());
                }
              });
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onOpen,
    required this.onResolve,
  });

  final ChannelReport report;
  final VoidCallback onOpen;
  final void Function(ReportResolution resolution) onResolve;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(report.createdAt.toLocal());
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
