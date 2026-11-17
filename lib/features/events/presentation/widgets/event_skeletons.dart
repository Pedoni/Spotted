import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/presentation/widgets/event_card.dart';

/// Scheletro di un elenco di eventi: card vere con dati finti.
class EventCardsSkeleton extends StatelessWidget {
  const EventCardsSkeleton({this.count = 3, super.key});

  final int count;

  static const _titles = [
    'Titolo di un evento',
    'Un titolo più lungo per un altro evento',
    'Un altro titolo',
  ];

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            EventCard(
              event: ChannelEvent(
                id: 'skeleton-$i',
                channelId: 'skeleton',
                channelName: 'Nome del canale',
                channelSlug: 'skeleton',
                title: _titles[i % _titles.length],
                description: "La descrizione dell'evento, su più righe.",
                location: 'Luogo',
                startsAt: DateTime(2026, 1, 15, 18),
                createdAt: DateTime(2026),
              ),
              maxDescriptionLines: 2,
            ),
        ],
      ),
    );
  }
}

/// Scheletro del modulo per scrivere un evento.
class EventFormSkeleton extends StatelessWidget {
  const EventFormSkeleton({super.key});

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
              minLines: 4,
              maxLines: 4,
              decoration: InputDecoration(labelText: 'Descrizione'),
            ),
            const SizedBox(height: 16),
            const TextField(
              enabled: false,
              decoration: InputDecoration(labelText: 'Inizio'),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () {}, child: const Text('Pubblica')),
          ],
        ),
      ),
    );
  }
}
