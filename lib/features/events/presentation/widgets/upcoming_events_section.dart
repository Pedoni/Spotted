import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/presentation/providers/followed_events_feed.dart';
import 'package:spotted/features/events/presentation/widgets/event_card.dart';
import 'package:spotted/features/home/presentation/widgets/home_carousel.dart';
import 'package:spotted/features/home/presentation/widgets/home_section_header.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Quante card di eventi mostra il carosello prima di "Visualizza tutti".
const upcomingEventsCarouselLimit = 5;

const _carouselHeight = 152.0;

/// "Prossimi eventi" nella Home: titolo con freccia e, sotto, un carosello
/// orizzontale con i prossimi eventi dei canali seguiti (fino a
/// [upcomingEventsCarouselLimit]), dal più vicino. Se sono di più, l'ultima
/// card è "Visualizza tutti". Senza eventi (anche perché non si segue nessun
/// canale) resta il titolo con un messaggio, senza freccia.
class UpcomingEventsSection extends ConsumerWidget {
  const UpcomingEventsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(followedEventsFeedProvider);

    final empty = feed.value?.items.isEmpty ?? false;
    final body = feed.when(
      loading: () => const UpcomingEventsCarouselSkeleton(),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: Text(failureMessage(l10n, error))),
            TextButton(
              onPressed: () => ref.invalidate(followedEventsFeedProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (paged) {
        if (paged.items.isEmpty) return const _EmptyUpcomingEvents();
        return HomeCarousel(
          height: _carouselHeight,
          onViewAll: paged.items.length > upcomingEventsCarouselLimit
              ? () => context.push(AppRoutes.upcomingEvents)
              : null,
          children: [
            for (final event in paged.items.take(upcomingEventsCarouselLimit))
              EventCarouselCard(
                event: event,
                onTap: () => context.push(AppRoutes.eventPath(event.id)),
              ),
          ],
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: l10n.upcomingEventsTitle,
          // Niente freccia se non c'è niente da vedere.
          onTap: feed.hasValue && !empty
              ? () => context.push(AppRoutes.upcomingEvents)
              : null,
        ),
        body,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _EmptyUpcomingEvents extends StatelessWidget {
  const _EmptyUpcomingEvents();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.noUpcomingEvents, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            l10n.noUpcomingEventsHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una card compatta del carosello: la data in evidenza, il canale, il titolo,
/// quando e dove.
class EventCarouselCard extends StatelessWidget {
  const EventCarouselCard({required this.event, this.onTap, super.key});

  final ChannelEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final location = event.location;

    return SizedBox(
      width: homeCardWidth,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: homeCardShape(theme),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventDateBadge(date: event.startsAt),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.channelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        formatTime(context, event.startsAt),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      if (location != null)
                        Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scheletro del carosello: card vere con dati finti.
class UpcomingEventsCarouselSkeleton extends StatelessWidget {
  const UpcomingEventsCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCarouselSkeleton(
      height: _carouselHeight,
      children: [
        for (var i = 0; i < 2; i++)
          EventCarouselCard(
            event: ChannelEvent(
              id: 'skeleton-$i',
              channelId: 'skeleton',
              channelName: 'Nome del canale',
              channelSlug: 'skeleton',
              title: 'Titolo di un evento',
              description: 'Descrizione',
              location: 'Luogo',
              startsAt: DateTime(2026, 1, 15, 18),
              createdAt: DateTime(2026),
            ),
          ),
      ],
    );
  }
}
