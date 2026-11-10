import 'package:flutter/material.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';

/// Uno spot: titolo, testo e data. Mai l'autore (gli spot sono anonimi).
class SpotCard extends StatelessWidget {
  const SpotCard({
    required this.spot,
    this.channelName,
    this.onChannelTap,
    this.trailing,
    super.key,
  });

  final Spot spot;

  /// Se presente, il canale è mostrato sopra il titolo ("I miei spot").
  final String? channelName;
  final VoidCallback? onChannelTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = MaterialLocalizations.of(context).formatShortDate(
      spot.createdAt.toLocal(),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
            const SizedBox(height: 8),
            Text(spot.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(spot.content),
          ],
        ),
      ),
    );
  }
}
