import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_skeletons.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';
import 'package:spotted/features/spots/presentation/providers/channel_spots_feed.dart';
import 'package:spotted/features/spots/presentation/widgets/channel_spots_sliver.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_skeletons.dart';
import 'package:spotted/features/subscriptions/presentation/providers/subscriptions_providers.dart';
import 'package:spotted/features/topics/presentation/providers/topics_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

class ChannelDetailPage extends ConsumerStatefulWidget {
  const ChannelDetailPage({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<ChannelDetailPage> createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends ConsumerState<ChannelDetailPage> {
  /// Quanto si aspetta, dopo l'ultima lettera scritta, prima di cercare.
  static const _searchDelay = Duration(milliseconds: 300);

  final _search = TextEditingController();
  Timer? _debounce;
  bool _searching = false;

  /// Il testo cercato, già senza spazi ai bordi e dopo l'attesa: è quello che
  /// guida la lista.
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() {
    _debounce?.cancel();
    _search.clear();
    setState(() {
      _searching = false;
      _query = '';
    });
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    final trimmed = text.trim();
    // Svuotare il campo toglie subito i risultati, senza attese.
    if (trimmed.isEmpty) {
      setState(() => _query = '');
      return;
    }
    // Aggiorna la "x" del campo.
    setState(() {});
    _debounce = Timer(_searchDelay, () {
      if (mounted) setState(() => _query = trimmed);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    setState(() => _query = '');
  }

  PreferredSizeWidget _searchBar(AppLocalizations l10n) {
    return AppBar(
      leading: IconButton(
        tooltip: l10n.closeSearch,
        icon: const Icon(Icons.arrow_back),
        onPressed: _closeSearch,
      ),
      title: TextField(
        controller: _search,
        autofocus: true,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.titleMedium,
        // Come gli altri campi, ma più basso per stare nella barra.
        decoration: InputDecoration(
          hintText: l10n.searchSpotsHint,
          isDense: true,
        ),
        onChanged: _onSearchChanged,
      ),
      actions: [
        if (_search.text.isNotEmpty)
          IconButton(
            tooltip: l10n.clearSearch,
            icon: const Icon(Icons.close),
            onPressed: _clearSearch,
          ),
      ],
    );
  }

  /// Gli spot trovati, o il suggerimento di scrivere di più.
  Widget _searchResults(AppLocalizations l10n, Channel channel) {
    if (!SpotValidators.isSearchLongEnough(_query)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.searchSpotsMinChars(SpotValidators.minSearchLength),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(
        channelSpotsFeedProvider(channel.id, query: _query).future,
      ),
      child: CustomScrollView(
        slivers: [
          ChannelSpotsSliver(channelId: channel.id, query: _query),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channel = ref.watch(channelDetailProvider(widget.slug));
    final topics = ref.watch(topicsProvider).value ?? const [];
    final searching = _searching && channel.hasValue;

    return PopScope(
      // Con la ricerca aperta, "indietro" la chiude invece di lasciare il
      // canale.
      canPop: !searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && searching) _closeSearch();
      },
      child: Scaffold(
        appBar: searching
            ? _searchBar(l10n)
            : AppBar(
                title: Text(channel.value?.name ?? ''),
                actions: [
                  if (channel.value case final loaded?) ...[
                    IconButton(
                      tooltip: l10n.searchSpotsTooltip,
                      icon: const Icon(Icons.search),
                      onPressed: _openSearch,
                    ),
                    _ModerationAction(channelId: loaded.id, slug: loaded.slug),
                  ],
                ],
              ),
        floatingActionButton: channel.hasValue && !searching
            ? FloatingActionButton.extended(
                onPressed: () =>
                    context.push(AppRoutes.spotNewPath(channel.value!.slug)),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.publishSpot),
              )
            : null,
        body: channel.when(
          loading: () => const SkeletonScroll(
            child: Column(
              children: [ChannelHeaderSkeleton(), SpotCardsSkeleton(count: 2)],
            ),
          ),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(channelDetailProvider(widget.slug)),
          ),
          data: (channel) {
            if (searching) return _searchResults(l10n, channel);

            final topicName = topics
                .where((t) => t.id == channel.topicId)
                .map((t) => t.name)
                .firstOrNull;
            final theme = Theme.of(context);
            return RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(channelSpotsFeedProvider(channel.id).future),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList.list(
                      children: [
                        Text(
                          channel.name,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (topicName != null) Chip(label: Text(topicName)),
                            if (channel.place != null)
                              Chip(
                                avatar: const Icon(
                                  Icons.place_outlined,
                                  size: 18,
                                ),
                                label: Text(channel.place!),
                              ),
                          ],
                        ),
                        if (channel.description != null) ...[
                          const SizedBox(height: 16),
                          Text(channel.description!),
                        ],
                        const SizedBox(height: 24),
                        _SubscriptionRow(channelId: channel.id),
                      ],
                    ),
                  ),
                  ChannelSpotsSliver(channelId: channel.id),
                  // Spazio per non coprire l'ultimo spot con il pulsante.
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Numero di iscritti e pulsante Segui / Smetti di seguire.
class _SubscriptionRow extends ConsumerWidget {
  const _SubscriptionRow({required this.channelId});

  final String channelId;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(channelSubscriptionProvider(channelId).notifier).toggle();
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(channelSubscriptionProvider(channelId)).value;
    // Mentre carica (o se fallisce) non mostriamo niente: il canale resta
    // consultabile.
    if (info == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(child: Text(l10n.subscribersCount(info.subscriberCount))),
        if (info.isSubscribed)
          OutlinedButton(
            onPressed: () => unawaited(_toggle(context, ref)),
            child: Text(l10n.unfollow),
          )
        else
          FilledButton(
            onPressed: () => unawaited(_toggle(context, ref)),
            child: Text(l10n.follow),
          ),
      ],
    );
  }
}

/// Pulsante "Moderazione": compare solo al proprietario del canale.
class _ModerationAction extends ConsumerWidget {
  const _ModerationAction({required this.channelId, required this.slug});

  final String channelId;
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(isChannelOwnerProvider(channelId)).value;
    if (isOwner != true) return const SizedBox.shrink();
    return IconButton(
      tooltip: AppLocalizations.of(context).moderationTitle,
      icon: const Icon(Icons.shield_outlined),
      onPressed: () => context.push(AppRoutes.channelModerationPath(slug)),
    );
  }
}
