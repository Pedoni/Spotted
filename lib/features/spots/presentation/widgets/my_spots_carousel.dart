import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';
import 'package:spotted/features/spots/domain/entities/spot_with_channel.dart';
import 'package:spotted/features/spots/presentation/providers/my_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/spot_interaction.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Quante card di spot mostra il carosello prima di "Visualizza tutti".
const mySpotsCarouselLimit = 5;

const _cardWidth = 260.0;
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
        _Header(onTap: empty ? null : () => context.push(AppRoutes.mySpots)),
        body,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onTap});

  /// Se è `null` la freccia non c'è.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.mySpotsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (onTap != null)
            IconButton(
              tooltip: l10n.viewAll,
              icon: const Icon(Icons.chevron_right),
              onPressed: onTap,
            )
          else
            const SizedBox(height: 48),
        ],
      ),
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
    return SizedBox(
      height: _carouselHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length + (showAll ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _ViewAllCard(onTap: () => context.push(AppRoutes.mySpots));
          }
          final item = items[index];
          return MySpotCard(
            item: item,
            onTap: () => context.push(AppRoutes.spotPath(item.spot.id)),
          );
        },
      ),
    );
  }
}

ShapeBorder _shape(ThemeData theme) => RoundedRectangleBorder(
  borderRadius: AppShapes.bubbleRadius,
  side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.5),
);

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
      width: _cardWidth,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: _shape(theme),
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
                      Icons.favorite_border,
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
                      Icons.chat_bubble_outline,
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
                        Icons.visibility_off_outlined,
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

class _ViewAllCard extends StatelessWidget {
  const _ViewAllCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.primaryContainer,
        shape: _shape(theme),
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.viewAll,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
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
class MySpotsCarouselSkeleton extends StatelessWidget {
  const MySpotsCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: SizedBox(
        height: _carouselHeight,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (var i = 0; i < 2; i++) ...[
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
              const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}
