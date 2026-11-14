import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/chat/presentation/providers/chats_feed.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_skeletons.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_tile.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Le chat dell'utente, dalla più recente.
class ChatsPage extends ConsumerWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(chatsFeedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatsTitle)),
      body: feed.when(
        loading: () => const SkeletonScroll(child: ChatTilesSkeleton()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(chatsFeedProvider),
        ),
        data: (paged) {
          if (paged.items.isEmpty) {
            return Center(child: Text(l10n.noChats));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(chatsFeedProvider.future),
            child: ListView.builder(
              itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < paged.items.length) {
                  return ChatTile(chat: paged.items[index]);
                }
                if (paged.loadMoreFailed) {
                  return ListTile(
                    title: Text(l10n.loadMoreChatsError),
                    trailing: TextButton(
                      onPressed: () => unawaited(
                        ref.read(chatsFeedProvider.notifier).loadMore(),
                      ),
                      child: Text(l10n.retry),
                    ),
                  );
                }
                // L'ultimo elemento è il caricamento: quando compare a
                // schermo si chiede la pagina successiva.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    unawaited(ref.read(chatsFeedProvider.notifier).loadMore());
                  }
                });
                return const ChatTilesSkeleton(count: 1);
              },
            ),
          );
        },
      ),
    );
  }
}
