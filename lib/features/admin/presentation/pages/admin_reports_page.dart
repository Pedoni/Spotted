import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/admin/domain/entities/admin_action.dart';
import 'package:spotted/features/admin/domain/entities/admin_report.dart';
import 'package:spotted/features/admin/presentation/providers/admin_providers.dart';
import 'package:spotted/features/admin/presentation/widgets/admin_report_card.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/presentation/widgets/report_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Le segnalazioni aperte di tutti i canali, per l'admin. Chi non è admin vede
/// l'errore di permesso (il database risponde `42501`): la voce nel Profilo
/// compare comunque solo agli admin.
class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  /// La segnalazione su cui si sta agendo: i suoi pulsanti sono fermi.
  String? _busyId;

  /// Rimuovere uno spot è definitivo: chiede conferma. Nascondere si può
  /// annullare (lo ripristina il proprietario), le altre azioni no ma non
  /// toccano il contenuto.
  Future<bool> _confirm(AdminReport report, AdminAction action) async {
    if (action != AdminAction.remove) return true;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminRemoveTitle),
        content: Text(l10n.adminRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.adminRemove),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _act(AdminReport report, AdminAction action) async {
    if (!await _confirm(report, action) || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = report.id);
    try {
      await ref.read(adminActionsProvider.notifier).act(report, action);
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (action) {
            AdminAction.dismiss => l10n.reportDismissed,
            AdminAction.resolve => l10n.reportResolved,
            AdminAction.hide =>
              report.kind == ReportKind.comment
                  ? l10n.commentHiddenDone
                  : l10n.spotHiddenDone,
            AdminAction.remove => l10n.spotRemovedDone,
          }),
        ),
      );
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(adminReportsFeedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminPanelTitle)),
      body: feed.when(
        loading: () => const SkeletonScroll(child: ReportCardsSkeleton()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(adminReportsFeedProvider),
        ),
        data: (paged) {
          if (paged.items.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.verified_user_rounded,
                title: l10n.adminNoReports,
                message: l10n.adminNoReportsHint,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminReportsFeedProvider.future),
            child: ListView.builder(
              itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < paged.items.length) {
                  final report = paged.items[index];
                  return AdminReportCard(
                    report: report,
                    busy: _busyId == report.id,
                    onAct: (action) => unawaited(_act(report, action)),
                  );
                }
                if (paged.loadMoreFailed) {
                  return ListTile(
                    title: Text(l10n.loadMoreReportsError),
                    trailing: TextButton(
                      onPressed: () => unawaited(
                        ref.read(adminReportsFeedProvider.notifier).loadMore(),
                      ),
                      child: Text(l10n.retry),
                    ),
                  );
                }
                // L'ultimo elemento è il caricamento: quando compare a schermo
                // si chiede la pagina successiva.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    unawaited(
                      ref.read(adminReportsFeedProvider.notifier).loadMore(),
                    );
                  }
                });
                return const ReportCardsSkeleton(count: 1);
              },
            ),
          );
        },
      ),
    );
  }
}
