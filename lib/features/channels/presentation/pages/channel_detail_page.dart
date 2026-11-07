import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/topics/presentation/providers/topics_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

class ChannelDetailPage extends ConsumerWidget {
  const ChannelDetailPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final channel = ref.watch(channelDetailProvider(slug));
    final topics = ref.watch(topicsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(channel.value?.name ?? '')),
      body: channel.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(channelDetailProvider(slug)),
        ),
        data: (channel) {
          final topicName = topics
              .where((t) => t.id == channel.topicId)
              .map((t) => t.name)
              .firstOrNull;
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(channel.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (topicName != null) Chip(label: Text(topicName)),
                  if (channel.place != null)
                    Chip(
                      avatar: const Icon(Icons.place_outlined, size: 18),
                      label: Text(channel.place!),
                    ),
                ],
              ),
              if (channel.description != null) ...[
                const SizedBox(height: 16),
                Text(channel.description!),
              ],
              const SizedBox(height: 32),
              Text(
                l10n.channelSpotsPlaceholder,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
