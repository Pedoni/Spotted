import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_form.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_header.dart';
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

/// Scheletro dell'intestazione di un canale: copertina, foto, nome, argomento
/// e luogo, descrizione, iscrizione e le schede.
class ChannelHeaderSkeleton extends StatelessWidget {
  const ChannelHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChannelHeader(
            channel: Channel(
              id: 'skeleton',
              name: 'Nome del canale',
              slug: 'skeleton',
              description: 'La descrizione del canale, su una o due righe.',
              place: 'Luogo',
              createdAt: DateTime(2026),
            ),
            topicName: 'Argomento',
            footer: Row(
              children: [
                const Expanded(child: Text('120 iscritti')),
                FilledButton(onPressed: () {}, child: const Text('Segui')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text('Spots'),
                SizedBox(width: 32),
                Text('Eventi'),
                SizedBox(width: 32),
                Text('News'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scheletro del modulo del canale (nome, argomento, comune, descrizione e
/// pulsante): il modulo vero con i campi vuoti.
class ChannelFormSkeleton extends StatelessWidget {
  const ChannelFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ChannelForm(submitLabel: 'Salva', onSubmit: (_) {}),
    );
  }
}
