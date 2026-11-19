import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/core/widgets/highlighted_text.dart';
import 'package:spotted/core/widgets/like_button.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';
import 'package:spotted/features/spots/presentation/providers/spot_interaction.dart';
import 'package:spotted/features/tags/presentation/widgets/spot_tag_chips.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Uno spot: titolo, testo, data, like e commenti. Mai l'autore (gli spot sono
/// anonimi).
class SpotCard extends ConsumerWidget {
  const SpotCard({
    required this.spot,
    this.onTap,
    this.channelName,
    this.onChannelTap,
    this.trailing,
    this.highlight,
    this.showStatus = true,
    super.key,
  });

  final Spot spot;

  /// Apre il dettaglio dello spot. Se è `null` (siamo già nel dettaglio) la
  /// card non è toccabile.
  final VoidCallback? onTap;

  /// Se presente, il canale è mostrato sopra il titolo ("I miei spot").
  final String? channelName;
  final VoidCallback? onChannelTap;
  final Widget? trailing;

  /// Il testo cercato: nel titolo e nel testo dello spot viene evidenziato.
  final String? highlight;

  /// Se mostrare perché lo spot non è pubblico (nascosto, in attesa,
  /// rifiutato). La coda del proprietario lo toglie: lì sono tutti in attesa.
  final bool showStatus;

  /// L'icona e il testo che spiegano perché uno spot non è pubblico (nascosto,
  /// in attesa o rifiutato); `null` se è pubblicato.
  static (IconData, String)? _statusNote(
    AppLocalizations l10n,
    SpotStatus status,
  ) => switch (status) {
    SpotStatus.published => null,
    SpotStatus.hidden => (Icons.visibility_off_rounded, l10n.hiddenSpotLabel),
    SpotStatus.pending => (Icons.hourglass_top_rounded, l10n.pendingSpotLabel),
    SpotStatus.rejected => (Icons.block_rounded, l10n.rejectedSpotLabel),
  };

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(spotInteractionProvider(spot.id).notifier)
          .toggleLike(spot);
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = SpotInteraction.effective(
      spot,
      ref.watch(spotInteractionProvider(spot.id)),
    );
    final date = formatDateTime(context, spot.createdAt);
    final note = showStatus
        ? _statusNote(AppLocalizations.of(context), spot.status)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      // A fumetto: l'angolo in basso a sinistra è quasi dritto.
      shape: RoundedRectangleBorder(
        borderRadius: AppShapes.bubbleRadius,
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (channelName != null) ...[
                    ChannelAvatar(
                      name: channelName!,
                      seed: spot.channelId,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: channelName == null
                        ? Text(date, style: theme.textTheme.labelSmall)
                        : InkWell(
                            onTap: onChannelTap,
                            child: Text(
                              '$channelName · $date',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                  ),
                  ?trailing,
                ],
              ),
              if (note case (final icon, final text)) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: spot.status == SpotStatus.pending
                          ? theme.colorScheme.outline
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        text,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: spot.status == SpotStatus.pending
                              ? theme.colorScheme.outline
                              : theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              HighlightedText(
                spot.title,
                query: highlight,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              HighlightedText(
                spot.content,
                query: highlight,
                style: theme.textTheme.bodyLarge,
              ),
              if (spot.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                SpotTagChips(tags: spot.tags),
              ],
              const SizedBox(height: 4),
              // Un "mi piace" o un commento ha senso solo su uno spot
              // pubblicato: uno in attesa o rifiutato non li ha.
              if (spot.status == SpotStatus.pending ||
                  spot.status == SpotStatus.rejected)
                const SizedBox(height: 8)
              else
                Row(
                  children: [
                    LikeButton(
                      liked: stats.likedByMe,
                      count: stats.likeCount,
                      onPressed: () => unawaited(_toggleLike(context, ref)),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.commentCount}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
