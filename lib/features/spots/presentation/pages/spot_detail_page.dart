import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/comments/presentation/providers/spot_comments_feed.dart';
import 'package:spotted/features/comments/presentation/widgets/comment_composer.dart';
import 'package:spotted/features/comments/presentation/widgets/spot_comments_sliver.dart';
import 'package:spotted/features/moderation/presentation/widgets/spot_moderation_menu.dart';
import 'package:spotted/features/spots/presentation/providers/spot_interaction.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Uno spot con i suoi commenti e il campo per scriverne uno.
class SpotDetailPage extends ConsumerWidget {
  const SpotDetailPage({required this.spotId, super.key});

  final String spotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spot = ref.watch(spotDetailProvider(spotId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.spotTitle),
        actions: [
          if (spot.value case final loaded?) SpotModerationMenu(spot: loaded),
        ],
      ),
      body: spot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(spotDetailProvider(spotId)),
        ),
        data: (spot) {
          final stats = SpotInteraction.effective(
            spot,
            ref.watch(spotInteractionProvider(spot.id)),
          );
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => Future.wait([
                    ref.refresh(spotDetailProvider(spotId).future),
                    ref.refresh(spotCommentsFeedProvider(spotId).future),
                  ]),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: SpotCard(spot: spot)),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            l10n.commentsCount(stats.commentCount),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                      SpotCommentsSliver(spot: spot),
                    ],
                  ),
                ),
              ),
              CommentComposer(spot: spot),
            ],
          );
        },
      ),
    );
  }
}
