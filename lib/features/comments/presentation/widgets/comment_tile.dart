import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/like_button.dart';
import 'package:spotted/features/comments/domain/entities/comment.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Un commento: autore (o "Autore del post"), testo, data, like e, se è
/// dell'utente, cancellazione.
class CommentTile extends StatelessWidget {
  const CommentTile({
    required this.comment,
    required this.onLike,
    required this.onDelete,
    super.key,
  });

  final Comment comment;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(comment.createdAt.toLocal());
    final author = comment.isSpotAuthor
        ? l10n.spotAuthor
        : '@${comment.authorUsername}';

    return Padding(
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
                          color: comment.isSpotAuthor
                              ? theme.colorScheme.primary
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
    );
  }
}
