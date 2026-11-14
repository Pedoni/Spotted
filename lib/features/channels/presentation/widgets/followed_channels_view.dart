import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_skeletons.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_tile.dart';
import 'package:spotted/features/subscriptions/presentation/providers/subscriptions_providers.dart';
import 'package:spotted/features/topics/presentation/providers/topics_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Seguiti: i canali a cui l'utente è iscritto.
class FollowedChannelsView extends ConsumerWidget {
  const FollowedChannelsView({required this.onExplore, super.key});

  /// Porta a "Esplora" quando non si segue ancora nessun canale.
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final channels = ref.watch(mySubscribedChannelsProvider);
    final topics = ref.watch(topicsProvider).value ?? const [];
    final topicNames = {for (final t in topics) t.id: t.name};

    return channels.when(
      loading: () => const SkeletonScroll(child: ChannelTilesSkeleton()),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(mySubscribedChannelsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.homeEmpty,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.homeEmptyHint, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onExplore,
                    child: Text(l10n.homeDiscoverChannels),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(mySubscribedChannelsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final channel = items[index];
              return ChannelTile(
                channel: channel,
                topicName: topicNames[channel.topicId],
                onTap: () => context.push(AppRoutes.channelPath(channel.slug)),
              );
            },
          ),
        );
      },
    );
  }
}
