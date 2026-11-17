import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/presentation/providers/event_actions.dart';
import 'package:spotted/features/events/presentation/providers/events_providers.dart';
import 'package:spotted/features/events/presentation/widgets/event_card.dart';
import 'package:spotted/features/events/presentation/widgets/event_skeletons.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Un evento per intero. Il proprietario del canale può modificarlo o
/// eliminarlo.
class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final event = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventTitle),
        actions: [
          if (event.value case final loaded?) _OwnerMenu(event: loaded),
        ],
      ),
      body: event.when(
        loading: () =>
            const SkeletonScroll(child: EventCardsSkeleton(count: 1)),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(eventDetailProvider(eventId)),
        ),
        data: (event) => SingleChildScrollView(
          child: EventCard(
            event: event,
            showChannel: true,
            onChannelTap: () => unawaited(
              context.push(AppRoutes.channelPath(event.channelSlug)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modifica ed elimina: li vede solo il proprietario del canale.
class _OwnerMenu extends ConsumerWidget {
  const _OwnerMenu({required this.event});

  final ChannelEvent event;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteEventTitle),
        content: Text(l10n.deleteEventBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Letto prima dell'attesa: la pagina può sparire mentre si aspetta.
    final actions = ref.read(eventActionsProvider.notifier);
    try {
      await actions.delete(event.id);
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventDeleted)));
    router.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isOwner = ref.watch(isChannelOwnerProvider(event.channelId)).value;
    if (isOwner != true) return const SizedBox.shrink();

    return PopupMenuButton<_EventAction>(
      tooltip: l10n.eventActionsTooltip,
      onSelected: (action) {
        switch (action) {
          case _EventAction.edit:
            unawaited(context.push(AppRoutes.eventEditPath(event.id)));
          case _EventAction.delete:
            unawaited(_confirmDelete(context, ref));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _EventAction.edit,
          child: Text(l10n.editEventAction),
        ),
        PopupMenuItem(
          value: _EventAction.delete,
          child: Text(l10n.deleteEventAction),
        ),
      ],
    );
  }
}

enum _EventAction { edit, delete }
