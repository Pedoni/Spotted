import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/features/channels/presentation/widgets/explore_channels_view.dart';
import 'package:spotted/features/channels/presentation/widgets/followed_channels_view.dart';
import 'package:spotted/features/channels/presentation/widgets/my_channels_view.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Scheda Canali: tre schede (Esplora, Seguiti, Miei) tra cui si può anche
/// scorrere di lato.
class ChannelsPage extends StatefulWidget {
  const ChannelsPage({super.key});

  @override
  State<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends State<ChannelsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.channelsTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.channelsExplore),
            Tab(text: l10n.channelsFollowed),
            Tab(text: l10n.channelsMine),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'channels-new',
        onPressed: () => context.push(AppRoutes.channelNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.newChannel),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const ExploreChannelsView(),
          FollowedChannelsView(onExplore: () => _tabs.animateTo(0)),
          const MyChannelsView(),
        ],
      ),
    );
  }
}
