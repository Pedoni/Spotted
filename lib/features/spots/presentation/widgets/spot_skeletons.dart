import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';

/// Scheletro di un elenco di spot: card vere con dati finti, di lunghezze
/// diverse. Con [withChannel] ognuna mostra anche il canale ("I miei spot").
class SpotCardsSkeleton extends StatelessWidget {
  const SpotCardsSkeleton({
    this.count = 3,
    this.withChannel = false,
    super.key,
  });

  final int count;
  final bool withChannel;

  static const _titles = [
    'Titolo di uno spot',
    'Un titolo più lungo per un altro spot',
    'Un altro titolo',
  ];

  static const _contents = [
    'Il testo dello spot, su più righe, come farebbe uno spot vero.',
    'Un testo più corto.',
    'Un testo di media lunghezza che occupa un paio di righe nella card.',
  ];

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            SpotCard(
              spot: Spot(
                id: 'skeleton-$i',
                channelId: 'skeleton',
                title: _titles[i % _titles.length],
                content: _contents[i % _contents.length],
                createdAt: DateTime(2026),
                stats: const SpotStats(likeCount: 12, commentCount: 3),
              ),
              channelName: withChannel ? 'Nome del canale' : null,
            ),
        ],
      ),
    );
  }
}

/// Scheletro del modulo per scrivere uno spot (titolo, testo, pulsante).
class SpotFormSkeleton extends StatelessWidget {
  const SpotFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const TextField(
              enabled: false,
              decoration: InputDecoration(labelText: 'Titolo'),
            ),
            const SizedBox(height: 16),
            const TextField(
              enabled: false,
              minLines: 5,
              maxLines: 5,
              decoration: InputDecoration(labelText: 'Testo'),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () {}, child: const Text('Pubblica')),
          ],
        ),
      ),
    );
  }
}
