import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/features/home/presentation/widgets/home_carousel.dart';
import 'package:spotted/features/home/presentation/widgets/home_section_header.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';
import 'package:spotted/features/spots/domain/entities/spot_with_channel.dart';
import 'package:spotted/features/spots/presentation/providers/my_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/spot_interaction.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Quante card di spot mostra il carosello prima di "Visualizza tutti".
const mySpotsCarouselLimit = 5;

const _carouselHeight = 176.0;

/// "I miei spot" nella Home: titolo con freccia e, sotto, un carosello
/// orizzontale con gli ultimi spot scritti dall'utente (fino a
/// [mySpotsCarouselLimit]). Se sono di più, l'ultima card è "Visualizza tutti".
/// Senza spot c'è solo il titolo con un invito a pubblicare (niente freccia:
/// non c'è niente da vedere).
class MySpotsSection extends ConsumerWidget {
  const MySpotsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(mySpotsFeedProvider);

    final body = feed.when(
      loading: () => const MySpotsCarouselSkeleton(),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: Text(failureMessage(l10n, error))),
            TextButton(
              onPressed: () => ref.invalidate(mySpotsFeedProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (paged) {
        if (paged.items.isEmpty) return const _EmptyMySpots();
        return _Carousel(
          items: paged.items.take(mySpotsCarouselLimit).toList(),
          showAll: paged.items.length > mySpotsCarouselLimit,
        );
      },
    );
    final empty = feed.value?.items.isEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: l10n.mySpotsTitle,
          onTap: empty ? null : () => context.push(AppRoutes.mySpots),
        ),
        body,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _EmptyMySpots extends StatelessWidget {
  const _EmptyMySpots();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.noMySpots, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            l10n.homeMySpotsEmptyHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Carousel extends StatelessWidget {
  const _Carousel({required this.items, required this.showAll});

  final List<SpotWithChannel> items;
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    return HomeCarousel(
      height: _carouselHeight,
      onViewAll: showAll ? () => context.push(AppRoutes.mySpots) : null,
      children: [
        for (final item in items)
          MySpotCard(
            item: item,
            onTap: () => context.push(AppRoutes.spotPath(item.spot.id)),
          ),
      ],
    );
  }
}

/// Una card compatta del carosello: canale, titolo, inizio del testo e
/// conteggi.
class MySpotCard extends ConsumerWidget {
  const MySpotCard({required this.item, this.onTap, super.key});

  final SpotWithChannel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spot = item.spot;
    final stats = SpotInteraction.effective(
      spot,
      ref.watch(spotInteractionProvider(spot.id)),
    );
    final hidden = spot.status == SpotStatus.hidden;
    final date = formatDateTime(context, spot.createdAt);

    return SizedBox(
      width: homeCardWidth,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: homeCardShape(theme),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.channelName} · $date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  spot.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    spot.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.likeCount}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.commentCount}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    if (hidden) ...[
                      const Spacer(),
                      Icon(
                        Icons.visibility_off_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ],
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
class MySpotsCarouselSkeleton extends StatelessWidget {
  const MySpotsCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCarouselSkeleton(
      height: _carouselHeight,
      children: [
        for (var i = 0; i < 2; i++)
          MySpotCard(
            item: SpotWithChannel(
              spot: Spot(
                id: 'skeleton-$i',
                channelId: 'skeleton',
                title: 'Titolo di uno spot',
                content: 'Il testo dello spot, su più righe.',
                createdAt: DateTime(2026),
                stats: const SpotStats(likeCount: 12, commentCount: 3),
              ),
              channelName: 'Nome del canale',
              channelSlug: 'skeleton',
            ),
          ),
      ],
    );
  }
}
