import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/features/reports/presentation/providers/reports_providers.dart';
import 'package:spotted/features/reports/presentation/widgets/report_dialog.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Segnala uno spot: chiede il motivo, invia e conferma con un messaggio.
Future<void> reportSpotFlow(
  BuildContext context,
  WidgetRef ref,
  String spotId,
) {
  return _report(
    context,
    (draft) => ref.read(reportSpotUseCaseProvider)(
      spotId: spotId,
      reason: draft.reason,
      details: draft.details,
    ),
  );
}

/// Segnala un commento: chiede il motivo, invia e conferma con un messaggio.
Future<void> reportCommentFlow(
  BuildContext context,
  WidgetRef ref,
  String commentId,
) {
  return _report(
    context,
    (draft) => ref.read(reportCommentUseCaseProvider)(
      commentId: commentId,
      reason: draft.reason,
      details: draft.details,
    ),
  );
}

Future<void> _report(
  BuildContext context,
  Future<void> Function(ReportDraft draft) send,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final draft = await showReportDialog(context);
  if (draft == null) return;
  try {
    await send(draft);
    messenger.showSnackBar(SnackBar(content: Text(l10n.reportSent)));
  } on Exception catch (error) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (error) {
          ConflictFailure() => l10n.reportAlreadySent,
          PermissionFailure() => l10n.reportOwnContent,
          _ => failureMessage(l10n, error),
        }),
      ),
    );
  }
}
