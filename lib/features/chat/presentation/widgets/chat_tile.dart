import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/core/widgets/user_avatar.dart';
import 'package:spotted/features/chat/domain/entities/chat_message_kind.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_names.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Una chat nell'elenco: l'altra persona (o l'autore anonimo), lo spot e
/// l'ultimo messaggio.
class ChatTile extends StatelessWidget {
  const ChatTile({required this.chat, super.key});

  final ChatSummary chat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unread = chat.unread;
    final last = chat.lastMessage;
    final lastKind = chat.lastMessageKind ?? ChatMessageKind.text;
    final preview = last == null
        ? l10n.noMessagesYet
        : lastKind.isSystem
        ? systemMessageText(l10n, chat, lastKind)
        : (chat.lastMessageIsMine ?? false)
        ? l10n.youPrefix(last)
        : last;
    // Sotto il nome: lo spot (chat degli spot) o il canale (il proprietario,
    // che gestisce più canali).
    final context_ = chat.isChannelChat
        ? (chat.iAmAuthor ? chat.channelName : null)
        : chat.spotTitle;

    return ListTile(
      leading: chat.isChannelChat && !chat.iAmAuthor
          ? ChannelAvatar(name: chat.channelName, seed: chat.channelSlug)
          : UserAvatar(username: chat.otherUsername),
      // Non letta: nome e anteprima in grassetto e un puntino, come i DM non
      // letti di Instagram.
      title: Text(
        chatPartnerName(l10n, chat),
        style: unread
            ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
            : null,
      ),
      subtitle: Text(
        context_ == null ? preview : '$context_\n$preview',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: unread
            ? theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              )
            : null,
      ),
      isThreeLine: context_ != null,
      trailing: unread
          ? Semantics(
              label: l10n.unreadChat,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: theme.colorScheme.primary,
                  shape: const CircleBorder(),
                ),
                child: const SizedBox.square(dimension: 10),
              ),
            )
          : null,
      onTap: () => context.push(AppRoutes.chatPath(chat.id)),
    );
  }
}
