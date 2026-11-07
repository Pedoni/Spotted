import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_tile.dart';
import 'package:spotted/features/subscriptions/presentation/providers/subscriptions_providers.dart';
import 'package:spotted/features/topics/presentation/providers/topics_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Home: i canali che l'utente segue (gli spot arriveranno con la 0.3.0).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final channels = ref.watch(mySubscribedChannelsProvider);
    final topics = ref.watch(topicsProvider).value ?? const [];
    final topicNames = {for (final t in topics) t.id: t.name};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: channels.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
                    FilledButton.tonal(
                      onPressed: () => context.go(AppRoutes.channels),
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
              itemCount: items.length,
              itemBuilder: (context, index) {
                final channel = items[index];
                return ChannelTile(
                  channel: channel,
                  topicName: topicNames[channel.topicId],
                  onTap: () =>
                      context.push(AppRoutes.channelPath(channel.slug)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
