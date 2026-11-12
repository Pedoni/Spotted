import 'package:flutter/material.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/core/widgets/like_button.dart';
import 'package:spotted/features/comments/domain/entities/comment.dart';
import 'package:spotted/features/comments/domain/entities/comment_status.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Un commento: autore (o "Autore del post"), testo, data, like e, se è
/// dell'utente, cancellazione.
class CommentTile extends StatelessWidget {
  const CommentTile({
    required this.comment,
    required this.onLike,
    required this.onDelete,
    this.onToggleHidden,
    this.onReport,
    this.onChat,
    super.key,
  });

  final Comment comment;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  /// Nasconde o ripristina il commento. Presente solo per il proprietario del
  /// canale.
  final VoidCallback? onToggleHidden;

  /// Segnala il commento. Assente per i propri commenti.
  final VoidCallback? onReport;

  /// Avvia una chat con chi ha scritto il commento. Presente solo per l'autore
  /// dello spot, e non sui suoi commenti.
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = formatDateTime(context, comment.createdAt);
    final author = comment.isSpotAuthor
        ? l10n.spotAuthor
        : '@${comment.authorUsername}';

    final hidden = comment.status == CommentStatus.hidden;

    return Opacity(
      opacity: hidden ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: author,
                          style: theme.textTheme.labelLarge?.copyWith(
                            // L'autore dello spot è anonimo: indaco.
                            color: comment.isSpotAuthor
                                ? theme.colorScheme.secondary
                                : null,
                          ),
                        ),
                        TextSpan(
                          text: '  $date',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  if (hidden)
                    Text(
                      l10n.hiddenCommentLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(comment.content),
                ],
              ),
            ),
            Column(
              children: [
                LikeButton(
                  liked: comment.likedByMe,
                  count: comment.likeCount,
                  onPressed: onLike,
                ),
                if (onToggleHidden != null)
                  IconButton(
                    tooltip: hidden ? l10n.restoreComment : l10n.hideComment,
                    icon: Icon(
                      hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: onToggleHidden,
                  ),
                if (onChat != null)
                  IconButton(
                    tooltip: l10n.startChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    onPressed: onChat,
                  ),
                if (onReport != null)
                  IconButton(
                    tooltip: l10n.report,
                    icon: const Icon(Icons.flag_outlined, size: 20),
                    onPressed: onReport,
                  ),
                if (comment.isMine)
                  IconButton(
                    tooltip: l10n.deleteComment,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
