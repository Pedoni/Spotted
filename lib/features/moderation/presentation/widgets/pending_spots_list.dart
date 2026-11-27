import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/moderation/presentation/providers/pending_spots_feed.dart';
import 'package:spotted/features/moderation/presentation/widgets/spot_decision_flows.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Gli spot che aspettano l'approvazione del proprietario, dal più vecchio.
/// Per ognuno: "Pubblica" (sceglie i tag) o "Rifiuta" (con conferma).
class PendingSpotsList extends ConsumerWidget {
  const PendingSpotsList({required this.channelId, super.key});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = pendingSpotsFeedProvider(channelId);
    final feed = ref.watch(provider);

    Future<void> reload() {
      ref.invalidate(pendingSpotsCountProvider(channelId));
      return ref.refresh(provider.future);
    }

    return feed.when(
      loading: () => const SkeletonScroll(child: SpotCardsSkeleton(count: 2)),
      error: (error, _) =>
          ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
      data: (paged) {
        if (paged.items.isEmpty) {
          return Center(
            child: EmptyState(
              icon: Icons.inbox_rounded,
              title: l10n.noPendingSpots,
              message: l10n.noPendingSpotsHint,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.builder(
            itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < paged.items.length) {
                final spot = paged.items[index];
                return Column(
                  children: [
                    SpotCard(
                      spot: spot,
                      showStatus: false,
                      onTap: () => context.push(AppRoutes.spotPath(spot.id)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                unawaited(rejectSpotFlow(context, ref, spot)),
                            child: Text(l10n.rejectSpotAction),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () =>
                                unawaited(approveSpotFlow(context, ref, spot)),
                            child: Text(l10n.approveSpotAction),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              // L'ultimo elemento è il caricamento: quando compare a schermo
              // si chiede la pagina successiva.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  unawaited(ref.read(provider.notifier).loadMore());
                }
              });
              return const SpotCardsSkeleton(count: 1);
            },
          ),
        );
      },
    );
  }
}
