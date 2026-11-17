import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/presentation/widgets/news_card.dart';

/// Scheletro di un elenco di news: card vere con dati finti, di lunghezze
/// diverse.
class NewsCardsSkeleton extends StatelessWidget {
  const NewsCardsSkeleton({this.count = 3, super.key});

  final int count;

  static const _titles = [
    'Titolo di una news',
    "Un titolo più lungo per un'altra news",
    'Un altro titolo',
  ];

  static const _bodies = [
    'Il testo della news, su più righe, come farebbe una news vera.',
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
            NewsCard(
              news: ChannelNews(
                id: 'skeleton-$i',
                channelId: 'skeleton',
                channelName: 'Nome del canale',
                channelSlug: 'skeleton',
                title: _titles[i % _titles.length],
                body: _bodies[i % _bodies.length],
                createdAt: DateTime(2026),
              ),
              maxBodyLines: 3,
            ),
        ],
      ),
    );
  }
}

/// Scheletro del modulo per scrivere una news (titolo, testo, pulsante).
class NewsFormSkeleton extends StatelessWidget {
  const NewsFormSkeleton({super.key});

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
