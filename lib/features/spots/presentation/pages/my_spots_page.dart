import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/spots/domain/entities/my_spot.dart';
import 'package:spotted/features/spots/presentation/providers/my_spots_feed.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

class MySpotsPage extends ConsumerWidget {
  const MySpotsPage({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MySpot item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSpotTitle),
        content: Text(l10n.deleteSpotBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteSpot),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(mySpotsFeedProvider.notifier).delete(item.spot.id);
      messenger.showSnackBar(SnackBar(content: Text(l10n.spotDeleted)));
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(mySpotsFeedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mySpotsTitle)),
      body: feed.when(
        loading: () =>
            const SkeletonScroll(child: SpotCardsSkeleton(withChannel: true)),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(mySpotsFeedProvider),
        ),
        data: (paged) {
          if (paged.items.isEmpty) {
            return Center(child: Text(l10n.noMySpots));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(mySpotsFeedProvider.future),
            child: ListView.builder(
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
                    trailing: IconButton(
                      tooltip: l10n.deleteSpot,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          unawaited(_confirmDelete(context, ref, item)),
                    ),
                  );
                }
                if (paged.loadMoreFailed) {
                  return ListTile(
                    title: Text(l10n.loadMoreSpotsError),
                    trailing: TextButton(
                      onPressed: () => unawaited(
                        ref.read(mySpotsFeedProvider.notifier).loadMore(),
                      ),
                      child: Text(l10n.retry),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    unawaited(
                      ref.read(mySpotsFeedProvider.notifier).loadMore(),
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
