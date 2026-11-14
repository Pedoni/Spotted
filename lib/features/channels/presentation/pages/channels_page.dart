import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/features/channels/presentation/widgets/explore_channels_view.dart';
import 'package:spotted/features/channels/presentation/widgets/followed_channels_view.dart';
import 'package:spotted/features/channels/presentation/widgets/my_channels_view.dart';
import 'package:spotted/l10n/app_localizations.dart';

enum _ChannelsSegment { explore, followed, mine }

/// Scheda Canali: tre viste, Esplora (tutti), Seguiti e Miei.
class ChannelsPage extends StatefulWidget {
  const ChannelsPage({super.key});

  @override
  State<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends State<ChannelsPage> {
  _ChannelsSegment _segment = _ChannelsSegment.explore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_ChannelsSegment>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _ChannelsSegment.explore,
                    label: Text(l10n.channelsExplore),
                  ),
                  ButtonSegment(
                    value: _ChannelsSegment.followed,
                    label: Text(l10n.channelsFollowed),
                  ),
                  ButtonSegment(
                    value: _ChannelsSegment.mine,
                    label: Text(l10n.channelsMine),
                  ),
                ],
                selected: {_segment},
                onSelectionChanged: (selection) =>
                    setState(() => _segment = selection.first),
              ),
            ),
          ),
          Expanded(
            child: switch (_segment) {
              _ChannelsSegment.explore => const ExploreChannelsView(),
              _ChannelsSegment.followed => FollowedChannelsView(
                onExplore: () =>
                    setState(() => _segment = _ChannelsSegment.explore),
              ),
              _ChannelsSegment.mine => const MyChannelsView(),
            },
          ),
        ],
      ),
    );
  }
}
