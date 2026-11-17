import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/empty_state.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Le schede di un canale, sotto gli iscritti.
enum ChannelTab { spots, events, news }

/// La barra delle schede (Spots, Eventi, News): resta ferma in cima mentre il
/// resto scorre.
class ChannelTabsBar extends StatelessWidget {
  const ChannelTabsBar({required this.controller, super.key});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabsDelegate(
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: controller,
            tabs: [
              Tab(text: l10n.channelTabSpots),
              Tab(text: l10n.channelTabEvents),
              Tab(text: l10n.channelTabNews),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  const _TabsDelegate(this.child);

  final Widget child;

  @override
  double get minExtent => kTextTabBarHeight;

  @override
  double get maxExtent => kTextTabBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_TabsDelegate oldDelegate) => oldDelegate.child != child;
}

/// Il contenuto delle schede che non hanno ancora niente (Eventi e News): lo
/// dicono, al centro dello spazio rimasto.
class ChannelEmptyTabSliver extends StatelessWidget {
  const ChannelEmptyTabSliver({required this.tab, super.key});

  final ChannelTab tab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, title, message) = switch (tab) {
      ChannelTab.events => (
        Icons.event_rounded,
        l10n.noEvents,
        l10n.noEventsHint,
      ),
      ChannelTab.news => (
        Icons.newspaper_rounded,
        l10n.noNews,
        l10n.noNewsHint,
      ),
      ChannelTab.spots => (
        Icons.article_rounded,
        l10n.noSpotsInChannel,
        l10n.noSpotsInChannelHint,
      ),
    };
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: EmptyState(icon: icon, title: title, message: message),
      ),
    );
  }
}
