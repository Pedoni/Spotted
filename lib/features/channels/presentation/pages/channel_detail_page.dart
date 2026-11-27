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
import 'package:spotted/features/channels/presentation/widgets/missing_municipality_banner.dart';
import 'package:spotted/features/chat/presentation/providers/chat_providers.dart';
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
import 'package:spotted/features/spots/presentation/widgets/spots_filter_bar.dart';
import 'package:spotted/features/subscriptions/presentation/providers/subscriptions_providers.dart';
import 'package:spotted/features/tags/presentation/widgets/tag_filter_sheet.dart';
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

  /// I tag scelti per filtrare gli spot (nomi tecnici).
  List<String> _tags = const [];

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

  /// Il testo cercato, che guida la lista solo da due lettere in su.
  String get _effectiveQuery =>
      SpotValidators.isSearchLongEnough(_query) ? _query : '';

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

  /// Toglie il testo e i tag: tutti gli spot del canale.
  void _clearFilters() {
    _debounce?.cancel();
    _search.clear();
    setState(() {
      _query = '';
      _tags = const [];
    });
  }

  Future<void> _openTagFilter(Channel channel) async {
    final chosen = await showTagFilterSheet(
      context,
      channelId: channel.id,
      selected: _tags,
    );
    if (chosen == null || !mounted) return;
    setState(() => _tags = chosen);
  }

  /// Il pulsante della scheda: "Pubblica uno spot" (di tutti), "Pubblica una
  /// news" e "Pubblica un evento" (solo del proprietario).
  Widget? _floatingButton(AppLocalizations l10n, Channel? channel) {
    if (channel == null) return null;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(channel.value?.name ?? ''),
        actions: [
          if (channel.value case final loaded?) _OwnerActions(channel: loaded),
        ],
      ),
      floatingActionButton: _floatingButton(l10n, channel.value),
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
                channelSpotsFeedProvider(
                  channel.id,
                  query: _effectiveQuery,
                  tags: spotTagsKey(_tags),
                ).future,
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
                    follow: _FollowButton(channelId: channel.id),
                    subscriberCount: ref
                        .watch(channelSubscriptionProvider(channel.id))
                        .value
                        ?.subscriberCount,
                  ),
                ),
                // Un canale nato senza città (quando era facoltativa): il
                // proprietario è invitato ad aggiungerla.
                if (channel.municipalityId == null &&
                    ref.watch(isChannelOwnerProvider(channel.id)).value == true)
                  SliverToBoxAdapter(
                    child: MissingMunicipalityBanner(
                      onAdd: () => unawaited(
                        context.push(AppRoutes.channelEditPath(channel.slug)),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 4)),
                ChannelTabsBar(controller: _tabs),
                if (_tab == ChannelTab.spots) ...[
                  // La ricerca e il filtro per tag, sempre visibili.
                  SliverToBoxAdapter(
                    child: SpotsFilterBar(
                      controller: _search,
                      tags: _tags,
                      onSearchChanged: _onSearchChanged,
                      onClearSearch: _clearSearch,
                      onOpenTagFilter: () => unawaited(_openTagFilter(channel)),
                      onRemoveTag: (tag) => setState(
                        () => _tags = [
                          for (final t in _tags)
                            if (t != tag) t,
                        ],
                      ),
                    ),
                  ),
                  ChannelSpotsSliver(
                    channelId: channel.id,
                    query: _effectiveQuery,
                    tags: spotTagsKey(_tags),
                    onClearFilters: _clearFilters,
                  ),
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

/// Il pulsante Segui / Smetti di seguire, in una riga bassa a destra della
/// foto del canale (vedi `ChannelHeader`). Il numero di iscritti sta in
/// sovrimpressione sulla copertina.
class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.channelId});

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

    final style = ChannelHeader.followButtonStyle;
    // Lo stato lo dice l'icona (una persona con il più o con il meno) e il
    // pulsante (pieno o con il bordo); il testo è breve, "Segui". Per chi non
    // vede il pulsante e per i lettori di schermo c'è la descrizione intera.
    return info.isSubscribed
        ? Tooltip(
            message: l10n.unfollow,
            child: OutlinedButton(
              style: style,
              onPressed: () => unawaited(_toggle(context, ref)),
              child: _label(Icons.person_remove_rounded, l10n.follow),
            ),
          )
        : Tooltip(
            message: l10n.follow,
            child: FilledButton(
              style: style,
              onPressed: () => unawaited(_toggle(context, ref)),
              child: _label(Icons.person_add_rounded, l10n.follow),
            ),
          );
  }

  /// Icona e testo su una riga; se lo spazio è poco il testo ha i puntini
  /// invece di uscire dallo schermo.
  Widget _label(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18),
      const SizedBox(width: 8),
      Flexible(
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
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

  /// Apre la chat con il canale (la crea se non c'è).
  Future<void> _writeToChannel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final chatId = await ref
          .read(chatActionsProvider.notifier)
          .startChannel(channel.id);
      unawaited(router.push(AppRoutes.chatPath(chatId)));
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isOwner = ref.watch(isChannelOwnerProvider(channel.id)).value;
    // Chi non è il proprietario può scrivere al canale. Finché non si sa chi
    // è (o se il controllo fallisce) non si mostra niente.
    if (isOwner == false) {
      return IconButton(
        tooltip: l10n.writeToChannel,
        icon: const Icon(Icons.forum_rounded),
        onPressed: () => unawaited(_writeToChannel(context, ref)),
      );
    }
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
