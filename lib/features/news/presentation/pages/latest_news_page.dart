import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/news/presentation/providers/followed_news_feed.dart';
import 'package:spotted/features/news/presentation/widgets/news_card.dart';
import 'package:spotted/features/news/presentation/widgets/news_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Tutte le news dei canali seguiti, dalla più recente (la freccia di "Ultime
/// news" nella Home).
class LatestNewsPage extends ConsumerWidget {
  const LatestNewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(followedNewsFeedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.latestNewsTitle)),
      body: feed.when(
        loading: () => const SkeletonScroll(child: NewsCardsSkeleton()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(followedNewsFeedProvider),
        ),
        data: (paged) {
          if (paged.items.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.newspaper_rounded,
                title: l10n.noLatestNews,
                message: l10n.noLatestNewsHint,
              ),
            );
          }
          return RefreshIndicator(
            // L'errore lo mostra la pagina, non il gesto di ricarica.
            onRefresh: () => ref
                .refresh(followedNewsFeedProvider.future)
                .then((_) {}, onError: (Object _) {}),
            child: ListView.builder(
              itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < paged.items.length) {
                  final news = paged.items[index];
                  return NewsCard(
                    news: news,
                    showChannel: true,
                    maxBodyLines: 3,
                    onTap: () =>
                        unawaited(context.push(AppRoutes.newsPath(news.id))),
                    onChannelTap: () => unawaited(
                      context.push(AppRoutes.channelPath(news.channelSlug)),
                    ),
                  );
                }
                if (paged.loadMoreFailed) {
                  return ListTile(
                    title: Text(l10n.loadMoreNewsError),
                    trailing: TextButton(
                      onPressed: () => unawaited(
                        ref.read(followedNewsFeedProvider.notifier).loadMore(),
                      ),
                      child: Text(l10n.retry),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    unawaited(
                      ref.read(followedNewsFeedProvider.notifier).loadMore(),
                    );
                  }
                });
                return const NewsCardsSkeleton(count: 1);
              },
            ),
          );
        },
      ),
    );
  }
}
