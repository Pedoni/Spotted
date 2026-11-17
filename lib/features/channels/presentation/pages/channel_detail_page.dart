import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/features/channels/presentation/providers/channel_actions.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/channels/presentation/services/channel_image_picker.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_header.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_image_dialog.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_skeletons.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_tabs.dart';
import 'package:spotted/features/events/domain/entities/events_when.dart';
import 'package:spotted/features/events/presentation/providers/channel_events_feed.dart';
import 'package:spotted/features/events/presentation/widgets/channel_events_sliver.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/news/presentation/providers/channel_news_feed.dart';
import 'package:spotted/features/news/presentation/widgets/channel_news_sliver.dart';
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

class _ChannelDetailPageState extends ConsumerState<ChannelDetailPage>
    with SingleTickerProviderStateMixin {
  /// Quanto si aspetta, dopo l'ultima lettera scritta, prima di cercare.
  static const _searchDelay = Duration(milliseconds: 300);

  final _search = TextEditingController();
  late final TabController _tabs = TabController(
    length: ChannelTab.values.length,
    vsync: this,
  );
  ChannelTab _tab = ChannelTab.spots;

  /// Quali eventi mostra la scheda Eventi: i prossimi o i passati.
  EventsWhen _eventsWhen = EventsWhen.upcoming;

  /// Le immagini che si stanno caricando o togliendo in questo momento.
  final _busyImages = <ChannelImageKind>{};
  Timer? _debounce;
  bool _searching = false;

  /// Il testo cercato, già senza spazi ai bordi e dopo l'attesa: è quello che
  /// guida la lista.
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      final tab = ChannelTab.values[_tabs.index];
      if (tab != _tab) setState(() => _tab = tab);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Cambia, scatta o toglie la foto o la copertina: la finestra, poi (per un
  /// file nuovo) la scelta, il ritaglio nella proporzione giusta e il
  /// caricamento.
  Future<void> _editImage(Channel channel, ChannelImageKind kind) async {
    if (_busyImages.contains(kind)) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isAvatar = kind == ChannelImageKind.avatar;
    final hasImage =
        (isAvatar ? channel.avatarPath : channel.coverPath) != null;

    final choice = await showChannelImageDialog(
      context,
      kind: kind,
      hasImage: hasImage,
    );
    if (choice == null || !mounted) return;

    try {
      final actions = ref.read(channelActionsProvider.notifier);
      if (choice == ChannelImageChoice.remove) {
        final confirmed = await confirmRemoveChannelImage(context, kind: kind);
        if (!confirmed || !mounted) return;
        setState(() => _busyImages.add(kind));
        await actions.removeImage(channel: channel, kind: kind);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(isAvatar ? l10n.photoRemoved : l10n.coverRemoved),
            ),
          );
        return;
      }

      final picked = await ref
          .read(channelImagePickerProvider)
          .pick(
            choice == ChannelImageChoice.camera
                ? ChannelImageSource.camera
                : ChannelImageSource.gallery,
          );
      if (picked == null || !mounted) return;
      final cropped = await ref
          .read(channelImageCropperProvider)
          .crop(context, picked, kind);
      if (cropped == null || !mounted) return;

      setState(() => _busyImages.add(kind));
      await actions.setImage(channel: channel, kind: kind, source: cropped);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(isAvatar ? l10n.photoUpdated : l10n.coverUpdated),
          ),
        );
    } on PlatformException {
      // La galleria o la fotocamera non si aprono (per esempio senza permesso).
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.errorImagePicker)));
    } on Exception catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(failureMessage(l10n, error))),
        );
    } finally {
      if (mounted) setState(() => _busyImages.remove(kind));
    }
  }

  void _openSearch() {
    // Si cerca tra gli spot.
    _tabs.index = ChannelTab.spots.index;
    setState(() => _searching = true);
  }

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
        icon: const Icon(Icons.arrow_back_rounded),
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
            icon: const Icon(Icons.close_rounded),
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
        // Anche con pochi contenuti si può tirare giù per ricaricare.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ChannelSpotsSliver(channelId: channel.id, query: _query),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  /// Il pulsante della scheda: "Pubblica uno spot" (di tutti), "Pubblica una
  /// news" e "Pubblica un evento" (solo del proprietario).
  Widget? _floatingButton(
    AppLocalizations l10n,
    Channel? channel,
    bool searching,
  ) {
    if (channel == null || searching) return null;
    switch (_tab) {
      case ChannelTab.spots:
        return FloatingActionButton.extended(
          onPressed: () =>
              unawaited(context.push(AppRoutes.spotNewPath(channel.slug))),
          icon: const Icon(Icons.edit_rounded),
          label: Text(l10n.publishSpot),
        );
      case ChannelTab.news:
        if (ref.watch(isChannelOwnerProvider(channel.id)).value != true) {
          return null;
        }
        return FloatingActionButton.extended(
          onPressed: () =>
              unawaited(context.push(AppRoutes.newsNewPath(channel.slug))),
          icon: const Icon(Icons.edit_rounded),
          label: Text(l10n.publishNews),
        );
      case ChannelTab.events:
        if (ref.watch(isChannelOwnerProvider(channel.id)).value != true) {
          return null;
        }
        return FloatingActionButton.extended(
          onPressed: () =>
              unawaited(context.push(AppRoutes.eventNewPath(channel.slug))),
          icon: const Icon(Icons.edit_rounded),
          label: Text(l10n.publishEvent),
        );
    }
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
                      icon: const Icon(Icons.search_rounded),
                      onPressed: _openSearch,
                    ),
                    _OwnerActions(channel: loaded),
                  ],
                ],
              ),
        floatingActionButton: _floatingButton(l10n, channel.value, searching),
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
            return RefreshIndicator(
              onRefresh: () => switch (_tab) {
                ChannelTab.news => ref.refresh(
                  channelNewsFeedProvider(channel.id).future,
                ),
                ChannelTab.events => ref.refresh(
                  channelEventsFeedProvider(channel.id, _eventsWhen).future,
                ),
                ChannelTab.spots => ref.refresh(
                  channelSpotsFeedProvider(channel.id).future,
                ),
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: ChannelHeader(
                      channel: channel,
                      topicName: topicName,
                      // Le matite sulle immagini sono solo del proprietario.
                      onEditImage:
                          ref.watch(isChannelOwnerProvider(channel.id)).value ==
                              true
                          ? (kind) => unawaited(_editImage(channel, kind))
                          : null,
                      busy: _busyImages,
                      footer: _SubscriptionRow(channelId: channel.id),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  ChannelTabsBar(controller: _tabs),
                  if (_tab == ChannelTab.spots) ...[
                    ChannelSpotsSliver(channelId: channel.id),
                    // Spazio per non coprire l'ultimo spot con il pulsante.
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ] else if (_tab == ChannelTab.news) ...[
                    ChannelNewsSliver(channelId: channel.id),
                    // Spazio per non coprire l'ultima news con il pulsante.
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ] else ...[
                    SliverToBoxAdapter(
                      child: _EventsWhenToggle(
                        value: _eventsWhen,
                        onChanged: (v) => setState(() => _eventsWhen = v),
                      ),
                    ),
                    ChannelEventsSliver(
                      channelId: channel.id,
                      when: _eventsWhen,
                    ),
                    // Spazio per non coprire l'ultimo evento con il pulsante.
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// "Prossimi" e "Passati": quali eventi del canale si vedono.
class _EventsWhenToggle extends StatelessWidget {
  const _EventsWhenToggle({required this.value, required this.onChanged});

  final EventsWhen value;
  final ValueChanged<EventsWhen> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SegmentedButton<EventsWhen>(
        segments: [
          ButtonSegment(
            value: EventsWhen.upcoming,
            label: Text(l10n.eventsUpcoming),
          ),
          ButtonSegment(value: EventsWhen.past, label: Text(l10n.eventsPast)),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.single),
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

/// Strumenti del proprietario del canale (gli altri non vedono niente):
/// "Moderazione" e un menu per modificare o eliminare il canale.
class _OwnerActions extends ConsumerWidget {
  const _OwnerActions({required this.channel});

  final Channel channel;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteChannelTitle),
        content: Text(l10n.deleteChannelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteChannelConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(channelActionsProvider.notifier).delete(channel);
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.channelDeleted)));
    // Il canale non c'è più: si torna all'elenco dei canali.
    router.go(AppRoutes.channels);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isOwner = ref.watch(isChannelOwnerProvider(channel.id)).value;
    if (isOwner != true) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.moderationTitle,
          icon: const Icon(Icons.shield_rounded),
          onPressed: () =>
              context.push(AppRoutes.channelModerationPath(channel.slug)),
        ),
        PopupMenuButton<_OwnerAction>(
          tooltip: l10n.channelActionsTooltip,
          onSelected: (action) {
            switch (action) {
              case _OwnerAction.edit:
                unawaited(
                  context.push(AppRoutes.channelEditPath(channel.slug)),
                );
              case _OwnerAction.delete:
                unawaited(_confirmDelete(context, ref));
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _OwnerAction.edit,
              child: Text(l10n.editChannelAction),
            ),
            PopupMenuItem(
              value: _OwnerAction.delete,
              child: Text(l10n.deleteChannelAction),
            ),
          ],
        ),
      ],
    );
  }
}

enum _OwnerAction { edit, delete }
