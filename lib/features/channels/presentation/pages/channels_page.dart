import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/channels/presentation/providers/channels_feed.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_tile.dart';
import 'package:spotted/features/topics/presentation/providers/topics_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

class ChannelsPage extends ConsumerStatefulWidget {
  const ChannelsPage({super.key});

  @override
  ConsumerState<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends ConsumerState<ChannelsPage> {
  static const _debounce = Duration(milliseconds: 400);

  final _search = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      ref.read(channelFilterProvider.notifier).setQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(channelsFeedProvider);
    final filter = ref.watch(channelFilterProvider);
    final topics = ref.watch(topicsProvider).value ?? const [];
    final topicNames = {for (final t in topics) t.id: t.name};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.channelsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.channelNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.newChannel),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchChannelsHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l10n.allTopics),
                    selected: filter.topicId == null,
                    onSelected: (_) =>
                        ref.read(channelFilterProvider.notifier).setTopic(null),
                  ),
                ),
                for (final topic in topics)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(topic.name),
                      selected: filter.topicId == topic.id,
                      onSelected: (_) => ref
                          .read(channelFilterProvider.notifier)
                          .setTopic(topic.id),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: feed.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(channelsFeedProvider),
              ),
              data: (paged) {
                if (paged.items.isEmpty) {
                  return Center(child: Text(l10n.noChannelsFound));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(channelsFeedProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == paged.items.length) {
                        if (paged.loadMoreFailed) {
                          return ListTile(
                            title: Text(l10n.loadMoreError),
                            trailing: TextButton(
                              onPressed: () => unawaited(
                                ref
                                    .read(channelsFeedProvider.notifier)
                                    .loadMore(),
                              ),
                              child: Text(l10n.retry),
                            ),
                          );
                        }
                        // L'ultimo elemento è il caricamento: quando compare
                        // a schermo si chiede la pagina successiva.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            unawaited(
                              ref
                                  .read(channelsFeedProvider.notifier)
                                  .loadMore(),
                            );
                          }
                        });
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final channel = paged.items[index];
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
          ),
        ],
      ),
    );
  }
}
