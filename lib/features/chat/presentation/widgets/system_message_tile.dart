import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/features/chat/domain/entities/chat_message.dart';
import 'package:spotted/features/chat/domain/entities/chat_message_kind.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_names.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Un messaggio di sistema al centro della chat con un canale: "Hai inviato uno
/// spot", "Il canale ha pubblicato il tuo spot", ... Sotto c'è il titolo dello
/// spot; se lo spot esiste ancora, toccandolo si apre.
class SystemMessageTile extends StatelessWidget {
  const SystemMessageTile({
    required this.message,
    required this.chat,
    super.key,
  });

  final ChatMessage message;
  final ChatSummary chat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spotId = message.spotId;
    final icon = switch (message.kind) {
      ChatMessageKind.spotApproved => Icons.check_circle_rounded,
      ChatMessageKind.spotRejected => Icons.block_rounded,
      _ => Icons.outbox_rounded,
    };
    final text = systemMessageText(l10n, chat, message.kind);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.9,
        ),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
          color: scheme.surfaceContainerLow,
          child: InkWell(
            onTap: spotId == null
                ? null
                : () => context.push(AppRoutes.spotPath(spotId)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: scheme.primary),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text, style: theme.textTheme.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          message.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (spotId != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.outline,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
