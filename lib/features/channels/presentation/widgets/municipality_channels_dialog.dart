import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/domain/entities/channel_map_pin.dart';
import 'package:spotted/features/channels/presentation/providers/channels_map_providers.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_skeletons.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_tile.dart';
import 'package:spotted/features/topics/presentation/providers/topics_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Apre la finestra con i canali di un comune (toccando un pin che ne ha più
/// di uno): il comune, quanti sono e l'elenco, che scorre. Toccando un canale
/// la finestra si chiude e si apre il canale.
Future<void> showMunicipalityChannelsDialog(
  BuildContext context,
  ChannelMapPin pin,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _MunicipalityChannelsDialog(pin: pin),
  );
}

class _MunicipalityChannelsDialog extends ConsumerWidget {
  const _MunicipalityChannelsDialog({required this.pin});

  final ChannelMapPin pin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = municipalityChannelsFeedProvider(pin.municipalityId);
    final feed = ref.watch(provider);
    final topics = ref.watch(topicsProvider).value ?? const [];
    final topicNames = {for (final t in topics) t.id: t.name};
    final height = MediaQuery.sizeOf(context).height * 0.6;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: height),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.municipalityLabel,
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          l10n.channelsCount(pin.channelCount),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: feed.when(
                loading: () =>
                    const SkeletonScroll(child: ChannelTilesSkeleton(count: 4)),
                error: (error, _) => ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(provider),
                ),
                data: (paged) => ListView.builder(
                  shrinkWrap: true,
                  itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < paged.items.length) {
                      final channel = paged.items[index];
                      return ChannelTile(
                        channel: channel,
                        topicName: topicNames[channel.topicId],
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(
                            context.push(AppRoutes.channelPath(channel.slug)),
                          );
                        },
                      );
                    }
                    if (paged.loadMoreFailed) {
                      return ListTile(
                        title: Text(l10n.loadMoreError),
                        trailing: TextButton(
                          onPressed: () => unawaited(
                            ref.read(provider.notifier).loadMore(),
                          ),
                          child: Text(l10n.retry),
                        ),
                      );
                    }
                    // L'ultimo elemento è il caricamento: quando compare si
                    // chiede la pagina successiva.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        unawaited(ref.read(provider.notifier).loadMore());
                      }
                    });
                    return const ChannelTilesSkeleton(count: 1);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
