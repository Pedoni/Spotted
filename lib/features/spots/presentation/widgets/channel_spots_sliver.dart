import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/spots/presentation/providers/channel_spots_feed.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Lista a scroll infinito degli spot di un canale, da usare dentro una
/// `CustomScrollView`.
class ChannelSpotsSliver extends ConsumerWidget {
  const ChannelSpotsSliver({
    required this.channelId,
    this.query = '',
    super.key,
  });

  final String channelId;

  /// Il testo cercato: se non è vuoto si vedono solo gli spot che lo
  /// contengono, con il testo evidenziato.
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = channelSpotsFeedProvider(channelId, query: query);
    final feed = ref.watch(provider);

    return feed.when(
      loading: () =>
          const SliverToBoxAdapter(child: SpotCardsSkeleton(count: 2)),
      error: (error, _) => SliverToBoxAdapter(
        child: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(provider),
        ),
      ),
      data: (paged) {
        if (paged.items.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  query.isEmpty
                      ? l10n.noSpotsInChannel
                      : l10n.noSpotResults(query),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return SliverList.builder(
          itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < paged.items.length) {
              final spot = paged.items[index];
              return SpotCard(
                spot: spot,
                highlight: query.isEmpty ? null : query,
                onTap: () => context.push(AppRoutes.spotPath(spot.id)),
              );
            }
            if (paged.loadMoreFailed) {
              return ListTile(
                title: Text(l10n.loadMoreSpotsError),
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
            return const SpotCardsSkeleton(count: 1);
          },
        );
      },
    );
  }
}
