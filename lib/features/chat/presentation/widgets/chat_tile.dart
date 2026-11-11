import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/user_avatar.dart';
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
    final last = chat.lastMessage;
    final preview = last == null
        ? l10n.noMessagesYet
        : (chat.lastMessageIsMine ?? false)
        ? l10n.youPrefix(last)
        : last;

    return ListTile(
      leading: UserAvatar(username: chat.otherUsername),
      title: Text(chatPartnerName(l10n, chat)),
      subtitle: Text(
        '${chat.spotTitle}\n$preview',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      onTap: () => context.push(AppRoutes.chatPath(chat.id)),
    );
  }
}
