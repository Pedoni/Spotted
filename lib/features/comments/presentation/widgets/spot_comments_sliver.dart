import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/chat/presentation/providers/chat_providers.dart';
import 'package:spotted/features/comments/domain/entities/comment.dart';
import 'package:spotted/features/comments/domain/entities/comment_status.dart';
import 'package:spotted/features/comments/presentation/providers/spot_comments_feed.dart';
import 'package:spotted/features/comments/presentation/widgets/comment_tile.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/reports/presentation/widgets/report_actions.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/presentation/providers/spot_interaction.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Lista a scroll infinito dei commenti di uno spot, da usare dentro una
/// `CustomScrollView`.
class SpotCommentsSliver extends ConsumerWidget {
  const SpotCommentsSliver({required this.spot, super.key});

  final Spot spot;

  Future<void> _like(
    BuildContext context,
    WidgetRef ref,
    Comment comment,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(spotCommentsFeedProvider(spot.id).notifier)
          .toggleLike(comment.id);
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Comment comment,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCommentTitle),
        content: Text(l10n.deleteCommentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(spotCommentsFeedProvider(spot.id).notifier)
          .delete(comment.id);
      ref.read(spotInteractionProvider(spot.id).notifier).addComments(spot, -1);
      messenger.showSnackBar(SnackBar(content: Text(l10n.commentDeleted)));
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  /// Avvia (o riapre) la chat con chi ha scritto il commento e la apre.
  Future<void> _startChat(
    BuildContext context,
    WidgetRef ref,
    Comment comment,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final chatId = await ref
          .read(chatActionsProvider.notifier)
          .start(comment.id);
      await router.push<void>(AppRoutes.chatPath(chatId));
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  /// Nasconde o ripristina un commento (solo il proprietario del canale).
  Future<void> _toggleHidden(
    BuildContext context,
    WidgetRef ref,
    Comment comment,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final hide = comment.status == CommentStatus.published;
    try {
      await ref
          .read(spotCommentsFeedProvider(spot.id).notifier)
          .setHidden(comment.id, hidden: hide);
      // Il numero di commenti conta solo quelli visibili a tutti.
      ref
          .read(spotInteractionProvider(spot.id).notifier)
          .addComments(spot, hide ? -1 : 1);
      messenger.showSnackBar(
        SnackBar(
          content: Text(hide ? l10n.commentHidden : l10n.commentRestored),
        ),
      );
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = spotCommentsFeedProvider(spot.id);
    final feed = ref.watch(provider);
    final isSpotAuthor =
        ref.watch(isSpotAuthorProvider(spot.id)).value ?? false;
    final isOwner =
        ref.watch(isChannelOwnerProvider(spot.channelId)).value ?? false;

    return feed.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
      ),
      data: (paged) {
        if (paged.items.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(l10n.noComments)),
            ),
          );
        }
        return SliverList.builder(
          itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < paged.items.length) {
              final comment = paged.items[index];
              return CommentTile(
                comment: comment,
                onLike: () => unawaited(_like(context, ref, comment)),
                onDelete: () => unawaited(_delete(context, ref, comment)),
                onChat: isSpotAuthor && !comment.isMine
                    ? () => unawaited(_startChat(context, ref, comment))
                    : null,
                onReport: comment.isMine
                    ? null
                    : () => unawaited(
                        reportCommentFlow(context, ref, comment.id),
                      ),
                onToggleHidden: isOwner
                    ? () => unawaited(_toggleHidden(context, ref, comment))
                    : null,
              );
            }
            if (paged.loadMoreFailed) {
              return ListTile(
                title: Text(l10n.loadMoreCommentsError),
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
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }
}
