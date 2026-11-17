import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/events/presentation/providers/followed_events_feed.dart';
import 'package:spotted/features/events/presentation/widgets/event_card.dart';
import 'package:spotted/features/events/presentation/widgets/event_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Tutti i prossimi eventi dei canali seguiti, dal più vicino (la freccia di
/// "Prossimi eventi" nella Home).
class UpcomingEventsPage extends ConsumerWidget {
  const UpcomingEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(followedEventsFeedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.upcomingEventsTitle)),
      body: feed.when(
        loading: () => const SkeletonScroll(child: EventCardsSkeleton()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(followedEventsFeedProvider),
        ),
        data: (paged) {
          if (paged.items.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.event_rounded,
                title: l10n.noUpcomingEvents,
                message: l10n.noUpcomingEventsHint,
              ),
            );
          }
          return RefreshIndicator(
            // L'errore lo mostra la pagina, non il gesto di ricarica.
            onRefresh: () => ref
                .refresh(followedEventsFeedProvider.future)
                .then((_) {}, onError: (Object _) {}),
            child: ListView.builder(
              itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < paged.items.length) {
                  final event = paged.items[index];
                  return EventCard(
                    event: event,
                    showChannel: true,
                    maxDescriptionLines: 2,
                    onTap: () =>
                        unawaited(context.push(AppRoutes.eventPath(event.id))),
                    onChannelTap: () => unawaited(
                      context.push(AppRoutes.channelPath(event.channelSlug)),
                    ),
                  );
                }
                if (paged.loadMoreFailed) {
                  return ListTile(
                    title: Text(l10n.loadMoreEventsError),
                    trailing: TextButton(
                      onPressed: () => unawaited(
                        ref
                            .read(followedEventsFeedProvider.notifier)
                            .loadMore(),
                      ),
                      child: Text(l10n.retry),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    unawaited(
                      ref.read(followedEventsFeedProvider.notifier).loadMore(),
                    );
                  }
                });
                return const EventCardsSkeleton(count: 1);
              },
            ),
          );
        },
      ),
    );
  }
}
