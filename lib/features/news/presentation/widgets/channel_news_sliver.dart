import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/news/presentation/providers/channel_news_feed.dart';
import 'package:spotted/features/news/presentation/widgets/news_card.dart';
import 'package:spotted/features/news/presentation/widgets/news_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Lista a scroll infinito delle news di un canale, da usare dentro una
/// `CustomScrollView`.
class ChannelNewsSliver extends ConsumerWidget {
  const ChannelNewsSliver({required this.channelId, super.key});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = channelNewsFeedProvider(channelId);
    final feed = ref.watch(provider);

    return feed.when(
      loading: () =>
          const SliverToBoxAdapter(child: NewsCardsSkeleton(count: 2)),
      error: (error, _) => SliverToBoxAdapter(
        child: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(provider),
        ),
      ),
      data: (paged) {
        if (paged.items.isEmpty) {
          // Occupa lo spazio rimasto sotto l'intestazione e si mette al centro.
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(
                icon: Icons.newspaper_rounded,
                title: l10n.noNews,
                message: l10n.noNewsHint,
              ),
            ),
          );
        }
        return SliverList.builder(
          itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < paged.items.length) {
              final news = paged.items[index];
              return NewsCard(
                news: news,
                maxBodyLines: 3,
                onTap: () => unawaited(
                  context.push(AppRoutes.newsPath(news.id)),
                ),
              );
            }
            if (paged.loadMoreFailed) {
              return ListTile(
                title: Text(l10n.loadMoreNewsError),
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
            return const NewsCardsSkeleton(count: 1);
          },
        );
      },
    );
  }
}
