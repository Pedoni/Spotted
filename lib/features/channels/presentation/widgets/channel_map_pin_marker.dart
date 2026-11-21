import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/format/count_format.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/core/widgets/squircle_avatar.dart';
import 'package:spotted/features/channels/domain/entities/channel_map_pin.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Il pin di un comune sulla mappa: la foto del canale se ce n'è uno solo, il
/// numero dei canali se sono di più. Un tocco lo apre ([onTap]).
class ChannelMapPinMarker extends ConsumerWidget {
  const ChannelMapPinMarker({
    required this.pin,
    required this.onTap,
    super.key,
  });

  /// Il lato del pin: la mappa lo usa anche per la dimensione del marcatore.
  static const size = 52.0;

  /// L'anello del colore dello sfondo attorno all'avatar.
  static const _ring = 4.0;

  /// Il lato dell'avatar (o del numero) dentro l'anello.
  static const double _inner = size - 2 * _ring;

  final ChannelMapPin pin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final channel = pin.channel;

    final Widget content;
    final String label;
    if (channel != null) {
      label = l10n.mapPinSingle(channel.name, pin.municipalityLabel);
      content = ChannelAvatar(
        name: channel.name,
        seed: channel.id,
        imageUrl: ref.watch(channelImageUrlProvider)(channel.avatarPath),
      );
    } else {
      label = l10n.mapPinMany(pin.channelCount, pin.municipalityLabel);
      // Stessa forma degli avatar dei canali (un quadrato dagli angoli molto
      // arrotondati), così i due tipi di pin sono della stessa famiglia.
      content = SquircleAvatar(
        background: scheme.primary,
        child: Text(
          formatCompactCount(pin.channelCount),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: scheme.onPrimary),
        ),
      );
    }

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          // Un anello del colore dello sfondo stacca il pin dalla mappa. Ha la
          // stessa forma dell'avatar (angoli arrotondati di quanto l'anello è
          // largo in più), non un cerchio.
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: scheme.surface,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(_inner * 0.36 + _ring),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(_ring),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
