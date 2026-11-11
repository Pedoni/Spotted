import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_tile.dart';

/// Scheletro di un elenco di canali.
class ChannelTilesSkeleton extends StatelessWidget {
  const ChannelTilesSkeleton({this.count = 6, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            ChannelTile(
              channel: Channel(
                id: 'skeleton-$i',
                name: 'Nome del canale',
                slug: 'skeleton',
                place: 'Luogo',
                createdAt: DateTime(2026),
              ),
              topicName: 'Argomento',
              onTap: () {},
            ),
        ],
      ),
    );
  }
}

/// Scheletro dell'intestazione di un canale: nome, argomento e luogo,
/// descrizione e iscrizione.
class ChannelHeaderSkeleton extends StatelessWidget {
  const ChannelHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nome del canale',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Argomento')),
                Chip(
                  avatar: Icon(Icons.place_outlined, size: 18),
                  label: Text('Luogo'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('La descrizione del canale, su una o due righe.'),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Text('120 iscritti')),
                FilledButton(onPressed: () {}, child: const Text('Segui')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
