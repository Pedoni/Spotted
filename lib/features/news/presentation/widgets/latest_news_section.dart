import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/home/presentation/widgets/home_section_header.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/presentation/providers/followed_news_feed.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Quante card di news mostra il carosello prima di "Visualizza tutti".
const latestNewsCarouselLimit = 5;

const _cardWidth = 260.0;
const _carouselHeight = 152.0;

/// "Ultime news" nella Home: titolo con freccia e, sotto, un carosello
/// orizzontale con le ultime news dei canali seguiti (fino a
/// [latestNewsCarouselLimit]). Se sono di più, l'ultima card è "Visualizza
/// tutti". Senza news (anche perché non si segue nessun canale) resta il titolo
/// con un messaggio, senza freccia.
class LatestNewsSection extends ConsumerWidget {
  const LatestNewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(followedNewsFeedProvider);

    return feed.when(
      loading: () => _Section(
        title: l10n.latestNewsTitle,
        child: const LatestNewsCarouselSkeleton(),
      ),
      error: (error, _) => _Section(
        title: l10n.latestNewsTitle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Text(failureMessage(l10n, error))),
              TextButton(
                onPressed: () => ref.invalidate(followedNewsFeedProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (paged) {
        if (paged.items.isEmpty) {
          // Niente freccia: non c'è niente da vedere.
          return _Section(
            title: l10n.latestNewsTitle,
            child: const _EmptyLatestNews(),
          );
        }
        return _Section(
          title: l10n.latestNewsTitle,
          onTap: () => context.push(AppRoutes.latestNews),
          child: _Carousel(
            items: paged.items.take(latestNewsCarouselLimit).toList(),
            showAll: paged.items.length > latestNewsCarouselLimit,
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.onTap});

  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(title: title, onTap: onTap),
        child,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _EmptyLatestNews extends StatelessWidget {
  const _EmptyLatestNews();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.noLatestNews, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            l10n.noLatestNewsHint,
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

  final List<ChannelNews> items;
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
            return _ViewAllCard(
              onTap: () => context.push(AppRoutes.latestNews),
            );
          }
          final news = items[index];
          return NewsCarouselCard(
            news: news,
            onTap: () => context.push(AppRoutes.newsPath(news.id)),
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

/// Una card compatta del carosello: canale e data, titolo e inizio del testo.
class NewsCarouselCard extends StatelessWidget {
  const NewsCarouselCard({required this.news, this.onTap, super.key});

  final ChannelNews news;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = formatDateTime(context, news.createdAt);

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
                  '${news.channelName} · $date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  news.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    news.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
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
                  Icons.arrow_forward_rounded,
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
class LatestNewsCarouselSkeleton extends StatelessWidget {
  const LatestNewsCarouselSkeleton({super.key});

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
              NewsCarouselCard(
                news: ChannelNews(
                  id: 'skeleton-$i',
                  channelId: 'skeleton',
                  channelName: 'Nome del canale',
                  channelSlug: 'skeleton',
                  title: 'Titolo di una news',
                  body: 'Il testo della news, su più righe.',
                  createdAt: DateTime(2026),
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
