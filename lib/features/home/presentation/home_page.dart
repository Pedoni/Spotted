import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/spots/presentation/providers/followed_spots_feed.dart';
import 'package:spotted/features/spots/presentation/widgets/channel_picker_sheet.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Home: gli spot dei canali seguiti, dal più recente, e il pulsante per
/// pubblicarne uno.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _publish(BuildContext context) async {
    final pick = await showChannelPickerSheet(context);
    if (pick == null || !context.mounted) return;
    switch (pick) {
      case PickedChannel(:final slug):
        await context.push(AppRoutes.spotNewPath(slug));
      case PickedSearch():
        context.go(AppRoutes.channels);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(followedSpotsFeedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      floatingActionButton: FloatingActionButton.extended(
        // Un tag diverso da quello di Canali: le schede stanno nello stesso
        // stack e due pulsanti con il tag di default fanno fallire le
        // transizioni.
        heroTag: 'home-publish',
        onPressed: () => unawaited(_publish(context)),
        icon: const Icon(Icons.edit_outlined),
        label: Text(l10n.publishSpotButton),
      ),
      body: feed.when(
        loading: () =>
            const SkeletonScroll(child: SpotCardsSkeleton(withChannel: true)),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(followedSpotsFeedProvider),
        ),
        data: (paged) {
          if (paged.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.homeFeedEmpty,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.homeFeedEmptyHint, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.channels),
                      child: Text(l10n.homeDiscoverChannels),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(followedSpotsFeedProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < paged.items.length) {
                  final item = paged.items[index];
                  return SpotCard(
                    spot: item.spot,
                    onTap: () => context.push(AppRoutes.spotPath(item.spot.id)),
                    channelName: item.channelName,
                    onChannelTap: () =>
                        context.push(AppRoutes.channelPath(item.channelSlug)),
                  );
                }
                if (paged.loadMoreFailed) {
                  return ListTile(
                    title: Text(l10n.loadMoreSpotsError),
                    trailing: TextButton(
                      onPressed: () => unawaited(
                        ref.read(followedSpotsFeedProvider.notifier).loadMore(),
                      ),
                      child: Text(l10n.retry),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    unawaited(
                      ref.read(followedSpotsFeedProvider.notifier).loadMore(),
                    );
                  }
                });
                return const SpotCardsSkeleton(count: 1, withChannel: true);
              },
            ),
          );
        },
      ),
    );
  }
}
