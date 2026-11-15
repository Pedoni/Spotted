import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_cover.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// L'intestazione di un canale: la copertina in cima, la foto quadrata che la
/// sovrappone a sinistra, poi nome, argomento e luogo, descrizione e, in
/// fondo, [footer] (gli iscritti e il pulsante Segui).
class ChannelHeader extends StatelessWidget {
  const ChannelHeader({
    required this.channel,
    required this.footer,
    this.topicName,
    super.key,
  });

  /// Quanto la foto esce dalla copertina.
  static const avatarOverlap = 44.0;
  static const avatarSize = 88.0;

  final Channel channel;
  final String? topicName;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    // Il bordo ha il colore dello sfondo, così la foto si stacca dalla
    // copertina.
    const ring = 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const ClipRRect(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              child: ChannelCover(),
            ),
            Positioned(
              left: 24 - ring,
              bottom: -(avatarOverlap + ring),
              child: Semantics(
                label: l10n.channelPhotoLabel(channel.name),
                child: Container(
                  padding: const EdgeInsets.all(ring),
                  decoration: ShapeDecoration(
                    color: scheme.surface,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(
                        avatarSize * 0.36 + ring,
                      ),
                    ),
                  ),
                  child: ChannelAvatar(
                    name: channel.name,
                    seed: channel.id,
                    size: avatarSize,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Lo spazio che la foto occupa sotto la copertina.
        const SizedBox(height: avatarOverlap + 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(channel.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (topicName != null) Chip(label: Text(topicName!)),
                  if (channel.place != null)
                    Chip(
                      avatar: const Icon(Icons.place_rounded, size: 18),
                      label: Text(channel.place!),
                    ),
                ],
              ),
              if (channel.description != null) ...[
                const SizedBox(height: 16),
                Text(channel.description!),
              ],
              const SizedBox(height: 24),
              footer,
            ],
          ),
        ),
      ],
    );
  }
}
