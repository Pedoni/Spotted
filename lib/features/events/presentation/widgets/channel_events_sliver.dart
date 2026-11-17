import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/events/domain/entities/events_when.dart';
import 'package:spotted/features/events/presentation/providers/channel_events_feed.dart';
import 'package:spotted/features/events/presentation/widgets/event_card.dart';
import 'package:spotted/features/events/presentation/widgets/event_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Lista a scroll infinito degli eventi di un canale (in corso o futuri,
/// oppure già finiti), da usare dentro una `CustomScrollView`.
class ChannelEventsSliver extends ConsumerWidget {
  const ChannelEventsSliver({
    required this.channelId,
    required this.when,
    super.key,
  });

  final String channelId;
  final EventsWhen when;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = channelEventsFeedProvider(channelId, when);
    final feed = ref.watch(provider);

    return feed.when(
      loading: () =>
          const SliverToBoxAdapter(child: EventCardsSkeleton(count: 2)),
      error: (error, _) => SliverToBoxAdapter(
        child: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(provider),
        ),
      ),
      data: (paged) {
        if (paged.items.isEmpty) {
          final upcoming = when == EventsWhen.upcoming;
          // Occupa lo spazio rimasto sotto l'intestazione e si mette al centro.
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(
                icon: Icons.event_rounded,
                title: upcoming ? l10n.noEvents : l10n.noPastEvents,
                message: upcoming ? l10n.noEventsHint : l10n.noPastEventsHint,
              ),
            ),
          );
        }
        return SliverList.builder(
          itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < paged.items.length) {
              final event = paged.items[index];
              return EventCard(
                event: event,
                maxDescriptionLines: 2,
                onTap: () =>
                    unawaited(context.push(AppRoutes.eventPath(event.id))),
              );
            }
            if (paged.loadMoreFailed) {
              return ListTile(
                title: Text(l10n.loadMoreEventsError),
                trailing: TextButton(
                  onPressed: () =>
                      unawaited(ref.read(provider.notifier).loadMore()),
                  child: Text(l10n.retry),
                ),
              );
            }
            // L'ultimo elemento è il caricamento: quando compare a schermo si
            // chiede la pagina successiva.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                unawaited(ref.read(provider.notifier).loadMore());
              }
            });
            return const EventCardsSkeleton(count: 1);
          },
        );
      },
    );
  }
}
