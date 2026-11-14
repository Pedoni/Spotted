import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_skeletons.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_tile.dart';
import 'package:spotted/features/topics/presentation/providers/topics_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Miei: i canali creati dall'utente.
class MyChannelsView extends ConsumerWidget {
  const MyChannelsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final channels = ref.watch(myChannelsProvider);
    final topics = ref.watch(topicsProvider).value ?? const [];
    final topicNames = {for (final t in topics) t.id: t.name};

    return channels.when(
      loading: () => const SkeletonScroll(child: ChannelTilesSkeleton()),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(myChannelsProvider),
      ),
      data: (items) {
        if (items.isEmpty) return Center(child: Text(l10n.noMyChannels));
        return RefreshIndicator(
          onRefresh: () => ref.refresh(myChannelsProvider.future),
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
