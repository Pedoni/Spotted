import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/core/widgets/like_button.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';
import 'package:spotted/features/spots/presentation/providers/spot_interaction.dart';
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
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(spot.createdAt.toLocal());

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
              if (spot.status == SpotStatus.hidden) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.visibility_off_outlined,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).hiddenSpotLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                spot.title,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(spot.content, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 4),
              Row(
                children: [
                  LikeButton(
                    liked: stats.likedByMe,
                    count: stats.likeCount,
                    onPressed: () => unawaited(_toggleLike(context, ref)),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chat_bubble_outline,
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
