import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/core/widgets/squircle_avatar.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';

/// Un evento: la data in evidenza (giorno e mese), il titolo, quando e dove.
/// Con [showChannel] mostra anche il canale (nelle liste che mescolano più
/// canali). Con [maxDescriptionLines] la descrizione si accorcia (nelle
/// liste); senza, si legge tutta (nel dettaglio).
class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    this.onTap,
    this.showChannel = false,
    this.onChannelTap,
    this.maxDescriptionLines,
    super.key,
  });

  final ChannelEvent event;

  /// Apre il dettaglio. Se è `null` (siamo già nel dettaglio) la card non è
  /// toccabile.
  final VoidCallback? onTap;
  final bool showChannel;

  /// Apre il canale (toccando il suo nome).
  final VoidCallback? onChannelTap;
  final int? maxDescriptionLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final location = event.location;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventDateBadge(date: event.startsAt),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showChannel) ...[
                      InkWell(
                        onTap: onChannelTap,
                        child: Text(
                          event.channelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      event.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDateTimeRange(
                        context,
                        event.startsAt,
                        event.endsAt,
                      ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    if (location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      maxLines: maxDescriptionLines,
                      overflow: maxDescriptionLines == null
                          ? null
                          : TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Il riquadro con il giorno e il mese ("14" e "MAR"), in lampone.
/// Decorativo: la data per esteso sta nel testo della card.
class EventDateBadge extends StatelessWidget {
  const EventDateBadge({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final local = date.toLocal();
    final month = DateFormat.MMM(
      Localizations.localeOf(context).toString(),
    ).format(local).toUpperCase().replaceAll('.', '');

    return SquircleAvatar(
      background: scheme.primaryContainer,
      size: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${local.day}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.onPrimaryContainer,
              height: 1,
            ),
          ),
          Text(
            month,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
