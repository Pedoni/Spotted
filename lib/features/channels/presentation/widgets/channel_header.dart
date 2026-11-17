import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/format/count_format.dart';
import 'package:spotted/core/theme/app_colors.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_cover.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_image_edit_button.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// L'intestazione di un canale: la copertina in cima, con in basso a destra, in
/// sovrimpressione, il numero di iscritti ([subscriberCount], in forma breve:
/// 999, 1K, 1.1K, 1M...); la foto quadrata che la sovrappone a sinistra e, a
/// destra della foto, sotto la copertina, [follow] (il pulsante Segui); poi
/// nome, argomento e luogo e descrizione. Lo spazio è poco di proposito: la
/// barra delle schede deve partire in alto.
///
/// Al proprietario ([onEditImage] presente) compare una matita sull'angolo in
/// basso a destra di ognuna delle due immagini; mentre se ne carica una
/// ([busy]) l'immagine si oscura e mostra l'avanzamento.
class ChannelHeader extends ConsumerWidget {
  const ChannelHeader({
    required this.channel,
    this.follow,
    this.subscriberCount,
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

  /// Altezza della fascia sotto la copertina, a destra della foto, dove sta
  /// [follow]: quanto la parte di foto che esce dalla copertina.
  static const double followBandHeight = avatarOverlap + ring;

  /// Distanza del numero di iscritti dal bordo basso e destro della copertina.
  static const badgeInset = 12.0;

  /// Altezza massima di [follow] dentro la fascia.
  static const followHeight = 40.0;

  /// Lo stile dei pulsanti Segui / Smetti di seguire: più bassi di quelli di
  /// default, perché la riga è alta quanto la parte di foto che esce dalla
  /// copertina.
  static ButtonStyle get followButtonStyle => ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size(64, followHeight)),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 20),
    ),
  );

  /// Da sinistra: il margine, la foto con il suo bordo e uno spazio.
  static const double followLeft = 24 - ring + avatarSize + 2 * ring + 12;

  final Channel channel;
  final String? topicName;

  /// Il pulsante Segui / Smetti di seguire, a destra della foto. `null` finché
  /// non si sa (la fascia resta vuota, così l'intestazione non salta).
  final Widget? follow;

  /// Il numero di iscritti, in sovrimpressione sulla copertina. `null`
  /// finché non si sa: non compare niente.
  final int? subscriberCount;

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
                  if (follow case final follow?)
                    Positioned(
                      left: followLeft,
                      right: 16,
                      top: coverHeight + (followBandHeight - followHeight) / 2,
                      height: followHeight,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: follow,
                      ),
                    ),
                  if (subscriberCount case final count?)
                    Positioned(
                      // Con la matita sulla copertina (solo al proprietario) si
                      // mette alla sua sinistra, senza coprirla.
                      right:
                          badgeInset +
                          (onEditImage == null
                              ? 0
                              : ChannelImageEditButton.size + 8),
                      bottom: followBandHeight + badgeInset + 2,
                      child: SubscribersBadge(count: count),
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
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(channel.name, style: theme.textTheme.headlineSmall),
              if (topicName != null || channel.place != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (topicName != null)
                      Chip(
                        label: Text(topicName!),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (channel.place != null)
                      Chip(
                        avatar: const Icon(Icons.place_rounded, size: 18),
                        label: Text(channel.place!),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              if (channel.description != null) ...[
                const SizedBox(height: 8),
                Text(channel.description!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Il numero di iscritti in una pillola scura con l'icona di un gruppo, per
/// stare sopra la copertina (qualunque sia l'immagine). Il testo è breve
/// ("1.1K"); il numero esatto è nell'etichetta per i lettori di schermo e nel
/// suggerimento.
class SubscribersBadge extends StatelessWidget {
  const SubscribersBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme.labelLarge;
    return Tooltip(
      message: l10n.subscribersCount(count),
      child: Semantics(
        label: l10n.subscribersCount(count),
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: AppColors.ink.withValues(alpha: 0.65),
            shape: const StadiumBorder(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatCompactCount(count),
                  style: text?.copyWith(color: AppColors.cream),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.groups_rounded,
                  size: 18,
                  color: AppColors.cream,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
