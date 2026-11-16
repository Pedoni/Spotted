import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_cover.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_image_edit_button.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// L'intestazione di un canale: la copertina in cima, la foto quadrata che la
/// sovrappone a sinistra, poi nome, argomento e luogo, descrizione e, in
/// fondo, [footer] (gli iscritti e il pulsante Segui).
///
/// Al proprietario ([onEditImage] presente) compare una matita sull'angolo in
/// basso a destra di ognuna delle due immagini; mentre se ne carica una
/// ([busy]) l'immagine si oscura e mostra l'avanzamento.
class ChannelHeader extends ConsumerWidget {
  const ChannelHeader({
    required this.channel,
    required this.footer,
    this.topicName,
    this.onEditImage,
    this.busy = const {},
    super.key,
  });

  /// Quanto la foto esce dalla copertina.
  static const avatarOverlap = 44.0;
  static const avatarSize = 88.0;

  /// Il bordo, del colore dello sfondo, che stacca la foto dalla copertina.
  static const ring = 4.0;

  final Channel channel;
  final String? topicName;
  final Widget footer;

  /// Chiamata quando il proprietario tocca la matita di un'immagine. `null`
  /// per chi non è il proprietario: niente matite.
  final ValueChanged<ChannelImageKind>? onEditImage;

  /// Le immagini che si stanno caricando in questo momento.
  final Set<ChannelImageKind> busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final urlOf = ref.watch(channelImageUrlProvider);
    final scrim = scheme.scrim.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // L'area è alta quanto la copertina più la parte di foto che ne esce:
        // fuori dall'area i tocchi non arriverebbero, e la matita in basso a
        // destra della foto non si potrebbe toccare.
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final coverHeight = ChannelCover.heightFor(width);
            return SizedBox(
              height: coverHeight + avatarOverlap + ring,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: coverHeight,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                      child: Stack(
                        children: [
                          ChannelCover(
                            imageUrl: urlOf(channel.coverPath),
                            height: coverHeight,
                          ),
                          if (busy.contains(ChannelImageKind.cover))
                            Positioned.fill(
                              child: ColoredBox(
                                color: scrim,
                                child: const Center(
                                  child: InlineProgress(size: 32),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (onEditImage case final edit?)
                    Positioned(
                      right: 12,
                      top: coverHeight - 12 - ChannelImageEditButton.size,
                      child: ChannelImageEditButton(
                        tooltip: l10n.editChannelCover,
                        onPressed: () => edit(ChannelImageKind.cover),
                      ),
                    ),
                  Positioned(
                    left: 24 - ring,
                    top: coverHeight - avatarOverlap - ring,
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
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ChannelAvatar(
                              name: channel.name,
                              seed: channel.id,
                              size: avatarSize,
                              imageUrl: urlOf(channel.avatarPath),
                            ),
                            if (busy.contains(ChannelImageKind.avatar))
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: ShapeDecoration(
                                    color: scrim,
                                    shape: RoundedSuperellipseBorder(
                                      borderRadius: BorderRadius.circular(
                                        avatarSize * 0.36,
                                      ),
                                    ),
                                  ),
                                  child: const Center(
                                    child: InlineProgress(size: 28),
                                  ),
                                ),
                              ),
                            if (onEditImage case final edit?)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: ChannelImageEditButton(
                                  tooltip: l10n.editChannelPhoto,
                                  onPressed: () =>
                                      edit(ChannelImageKind.avatar),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
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
