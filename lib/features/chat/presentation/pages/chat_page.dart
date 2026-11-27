import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/presentation/providers/chat_messages_feed.dart';
import 'package:spotted/features/chat/presentation/providers/chat_providers.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_names.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_skeletons.dart';
import 'package:spotted/features/chat/presentation/widgets/message_bubble.dart';
import 'package:spotted/features/chat/presentation/widgets/message_composer.dart';
import 'package:spotted/features/chat/presentation/widgets/system_message_tile.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Una chat: lo spot da cui nasce, i messaggi e il campo per scrivere. L'autore
/// può rivelare la sua identità; il commentatore vede l'autore come anonimo
/// finché non lo fa.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({required this.chatId, super.key});

  final String chatId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  String get chatId => widget.chatId;

  @override
  void initState() {
    super.initState();
    // Aprire la chat vuol dire averla letta.
    unawaited(
      Future.microtask(
        () => ref.read(chatActionsProvider.notifier).markRead(chatId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chat = ref.watch(chatDetailProvider(chatId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          chat.value == null ? '' : chatPartnerName(l10n, chat.value!),
        ),
        actions: [
          // Solo il proprietario, nelle chat con un canale.
          if (chat.value case final loaded?
              when loaded.isChannelChat && loaded.iAmAuthor)
            _BlockMenu(chat: loaded),
        ],
      ),
      body: chat.when(
        loading: () => const Column(
          children: [
            ChatHeaderSkeleton(),
            Expanded(child: MessagesSkeletonView(count: 4)),
          ],
        ),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(chatDetailProvider(chatId)),
        ),
        data: (chat) => Column(
          children: [
            _ChatHeader(chat: chat),
            Expanded(child: _Messages(chat: chat)),
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

    // Chat con un canale: nessuna identità da rivelare, solo una nota su chi
    // risponde.
    if (chat.isChannelChat) {
      final blocked =
          chat.iAmAuthor &&
          (ref.watch(chatUserBlockedProvider(chat.id)).value ?? false);
      return Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.forum_rounded),
            title: Text(chat.channelName, maxLines: 1),
            subtitle: Text(
              chat.iAmAuthor
                  ? l10n.chatChannelOwnerNote
                  : l10n.chatChannelUserNote,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.channelPath(chat.channelSlug)),
          ),
          if (blocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.block_rounded,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.chatUserBlockedNote('@${chat.otherUsername ?? ''}'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
        ],
      );
    }

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
          leading: const Icon(Icons.article_rounded),
          title: Text(chat.spotTitle ?? '', maxLines: 1),
          subtitle: Text(chat.channelName),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            final spotId = chat.spotId;
            if (spotId != null) {
              unawaited(context.push(AppRoutes.spotPath(spotId)));
            }
          },
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
  const _Messages({required this.chat});

  final ChatSummary chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = chatMessagesFeedProvider(chat.id);
    final feed = ref.watch(provider);

    return feed.when(
      loading: () => const MessagesSkeletonView(),
      error: (error, _) =>
          ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
      data: (paged) {
        if (paged.items.isEmpty) {
          return Center(
            child: EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: l10n.noMessages,
              compact: true,
            ),
          );
        }
        // I più recenti in basso: la lista scorre al contrario e i più vecchi
        // si caricano in cima.
        return ListView.builder(
          reverse: true,
          itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < paged.items.length) {
              final message = paged.items[index];
              return message.kind.isSystem
                  ? SystemMessageTile(message: message, chat: chat)
                  : MessageBubble(message: message);
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
            return const MessagesSkeleton(count: 2);
          },
        );
      },
    );
  }
}

enum _BlockAction { block, unblock }

/// "Blocca utente" / "Sblocca utente" nella chat di un canale, per il
/// proprietario. Bloccare chiede conferma.
class _BlockMenu extends ConsumerWidget {
  const _BlockMenu({required this.chat});

  final ChatSummary chat;

  Future<void> _change(
    BuildContext context,
    WidgetRef ref, {
    required bool block,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (block) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.blockUserTitle('@${chat.otherUsername ?? ''}')),
          content: Text(l10n.blockUserBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.blockAction),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      await ref
          .read(channelBlocksProvider.notifier)
          .setChatUserBlocked(chat.id, blocked: block);
      messenger.showSnackBar(
        SnackBar(
          content: Text(block ? l10n.userBlocked : l10n.userUnblocked),
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
    // Finché non si sa se è già bloccato (o se il controllo fallisce) non si
    // mostra niente.
    final blocked = ref.watch(chatUserBlockedProvider(chat.id)).value;
    if (blocked == null) return const SizedBox.shrink();

    return PopupMenuButton<_BlockAction>(
      tooltip: l10n.ownerTools,
      onSelected: (action) => unawaited(
        _change(context, ref, block: action == _BlockAction.block),
      ),
      itemBuilder: (context) => [
        if (blocked)
          PopupMenuItem(
            value: _BlockAction.unblock,
            child: Text(l10n.unblockUser),
          )
        else
          PopupMenuItem(
            value: _BlockAction.block,
            child: Text(l10n.blockUser),
          ),
      ],
    );
  }
}
