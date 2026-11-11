import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/features/moderation/domain/entities/moderation_status.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';
import 'package:spotted/l10n/app_localizations.dart';

enum _Action { viewAuthor, toggleHidden, remove }

/// Menu del proprietario del canale su uno spot: vedere l'autore, nascondere o
/// ripristinare, rimuovere. Per gli altri utenti non compare.
class SpotModerationMenu extends ConsumerWidget {
  const SpotModerationMenu({required this.spot, super.key});

  final Spot spot;

  Future<void> _viewAuthor(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final author = await ref.read(spotAuthorProvider(spot.id).future);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.spotAuthorDialogTitle),
          content: Text(l10n.spotAuthorDialogBody(author.username)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    ModerationStatus status,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    if (status == ModerationStatus.removed) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.removeSpotTitle),
          content: Text(l10n.removeSpotBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.removeSpot),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      await ref.read(spotModerationProvider.notifier).setStatus(spot, status);
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (status) {
            ModerationStatus.published => l10n.spotRestored,
            ModerationStatus.hidden => l10n.spotHidden,
            ModerationStatus.removed => l10n.spotRemoved,
          }),
        ),
      );
      // Uno spot rimosso non esiste più: si torna indietro.
      if (status == ModerationStatus.removed && router.canPop()) router.pop();
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(isChannelOwnerProvider(spot.channelId)).value;
    if (isOwner != true) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final hidden = spot.status == SpotStatus.hidden;
    return PopupMenuButton<_Action>(
      tooltip: l10n.ownerTools,
      onSelected: (action) => unawaited(switch (action) {
        _Action.viewAuthor => _viewAuthor(context, ref),
        _Action.toggleHidden => _setStatus(
          context,
          ref,
          hidden ? ModerationStatus.published : ModerationStatus.hidden,
        ),
        _Action.remove => _setStatus(context, ref, ModerationStatus.removed),
      }),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _Action.viewAuthor,
          child: Text(l10n.viewSpotAuthor),
        ),
        PopupMenuItem(
          value: _Action.toggleHidden,
          child: Text(hidden ? l10n.restoreSpot : l10n.hideSpot),
        ),
        PopupMenuItem(value: _Action.remove, child: Text(l10n.removeSpot)),
      ],
    );
  }
}
