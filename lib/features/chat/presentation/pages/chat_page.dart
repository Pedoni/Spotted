import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/presentation/providers/chat_messages_feed.dart';
import 'package:spotted/features/chat/presentation/providers/chat_providers.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_names.dart';
import 'package:spotted/features/chat/presentation/widgets/message_bubble.dart';
import 'package:spotted/features/chat/presentation/widgets/message_composer.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Una chat: lo spot da cui nasce, i messaggi e il campo per scrivere. L'autore
/// può rivelare la sua identità; il commentatore vede l'autore come anonimo
/// finché non lo fa.
class ChatPage extends ConsumerWidget {
  const ChatPage({required this.chatId, super.key});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chat = ref.watch(chatDetailProvider(chatId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          chat.value == null ? '' : chatPartnerName(l10n, chat.value!),
        ),
      ),
      body: chat.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(chatDetailProvider(chatId)),
        ),
        data: (chat) => Column(
          children: [
            _ChatHeader(chat: chat),
            Expanded(child: _Messages(chatId: chatId)),
            MessageComposer(chatId: chatId),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends ConsumerWidget {
  const _ChatHeader({required this.chat});

  final ChatSummary chat;

  Future<void> _reveal(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.revealIdentityTitle),
        content: Text(
          l10n.revealIdentityBody(chat.otherUsername ?? ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.revealIdentity),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(chatActionsProvider.notifier).reveal(chat.id);
      messenger.showSnackBar(SnackBar(content: Text(l10n.identityRevealed)));
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final String? note;
    if (chat.iAmAuthor) {
      note = chat.identityRevealed
          ? l10n.chatIdentityRevealedToThem
          : l10n.chatIdentityHiddenFromThem;
    } else {
      note = chat.identityRevealed ? null : l10n.chatAuthorAnonymous;
    }

    return Column(
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.article_outlined),
          title: Text(chat.spotTitle, maxLines: 1),
          subtitle: Text(chat.channelName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.spotPath(chat.spotId)),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Expanded(child: Text(note, style: theme.textTheme.bodySmall)),
                if (chat.iAmAuthor && !chat.identityRevealed)
                  TextButton(
                    onPressed: () => unawaited(_reveal(context, ref)),
                    child: Text(l10n.revealIdentity),
                  ),
              ],
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

class _Messages extends ConsumerWidget {
  const _Messages({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = chatMessagesFeedProvider(chatId);
    final feed = ref.watch(provider);

    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
      data: (paged) {
        if (paged.items.isEmpty) {
          return Center(child: Text(l10n.noMessages));
        }
        // I più recenti in basso: la lista scorre al contrario e i più vecchi
        // si caricano in cima.
        return ListView.builder(
          reverse: true,
          itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < paged.items.length) {
              return MessageBubble(message: paged.items[index]);
            }
            if (paged.loadMoreFailed) {
              return ListTile(
                title: Text(l10n.loadMoreMessagesError),
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
