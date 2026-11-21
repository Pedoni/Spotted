import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/core/widgets/user_avatar.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_skeletons.dart';
import 'package:spotted/features/moderation/domain/entities/blocked_user.dart';
import 'package:spotted/features/moderation/presentation/providers/blocked_users_feed.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Gli utenti che il canale ha bloccato, dal più recente, con "Sblocca".
class BlockedUsersList extends ConsumerWidget {
  const BlockedUsersList({required this.channelId, super.key});

  final String channelId;

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    BlockedUser user,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(channelBlocksProvider.notifier).unblock(user.id);
      messenger.showSnackBar(SnackBar(content: Text(l10n.userUnblocked)));
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = blockedUsersFeedProvider(channelId);
    final feed = ref.watch(provider);

    return feed.when(
      loading: () => const SkeletonScroll(child: ChatTilesSkeleton()),
      error: (error, _) =>
          ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
      data: (paged) {
        if (paged.items.isEmpty) {
          return Center(
            child: EmptyState(
              icon: Icons.block_rounded,
              title: l10n.noBlockedUsers,
              message: l10n.noBlockedUsersHint,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future),
          child: ListView.builder(
            itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < paged.items.length) {
                final user = paged.items[index];
                return ListTile(
                  leading: UserAvatar(username: user.username),
                  title: Text('@${user.username}'),
                  trailing: TextButton(
                    onPressed: () => unawaited(_unblock(context, ref, user)),
                    child: Text(l10n.unblockAction),
                  ),
                );
              }
              if (paged.loadMoreFailed) {
                return ListTile(
                  title: Text(l10n.loadMoreBlockedError),
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
              return const ChatTilesSkeleton(count: 1);
            },
          ),
        );
      },
    );
  }
}
