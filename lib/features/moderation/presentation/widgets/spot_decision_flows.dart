import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/moderation/presentation/widgets/approve_spot_sheet.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Il proprietario pubblica uno spot in attesa: sceglie i tag in un foglio e
/// conferma. Mostra l'esito (o l'errore) in una barra in basso.
Future<void> approveSpotFlow(
  BuildContext context,
  WidgetRef ref,
  Spot spot,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final tags = await showApproveSpotSheet(context, channelId: spot.channelId);
  if (tags == null) return;
  try {
    await ref.read(spotModerationProvider.notifier).approve(spot, tags);
    messenger.showSnackBar(SnackBar(content: Text(l10n.spotApproved)));
  } on Exception catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(failureMessage(l10n, error))),
    );
  }
}

/// Il proprietario rifiuta uno spot in attesa, dopo la conferma.
Future<void> rejectSpotFlow(
  BuildContext context,
  WidgetRef ref,
  Spot spot,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.rejectSpotTitle),
      content: Text(l10n.rejectSpotMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.rejectSpotAction),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ref.read(spotModerationProvider.notifier).reject(spot);
    messenger.showSnackBar(SnackBar(content: Text(l10n.spotRejected)));
  } on Exception catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(failureMessage(l10n, error))),
    );
  }
}
