import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_skeletons.dart';
import 'package:spotted/features/subscriptions/presentation/providers/subscriptions_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Cosa ha scelto l'utente nel foglio: un canale o la ricerca di un altro.
sealed class ChannelPick {
  const ChannelPick();
}

class PickedChannel extends ChannelPick {
  const PickedChannel(this.slug);

  final String slug;
}

class PickedSearch extends ChannelPick {
  const PickedSearch();
}

/// Foglio dal basso: i canali seguiti tra cui scegliere dove pubblicare, più
/// la strada per cercarne un altro.
Future<ChannelPick?> showChannelPickerSheet(BuildContext context) {
  return showModalBottomSheet<ChannelPick>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _ChannelPickerSheet(),
  );
}

class _ChannelPickerSheet extends ConsumerWidget {
  const _ChannelPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final channels = ref.watch(mySubscribedChannelsProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.pickChannelTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: channels.when(
                loading: () =>
                    const SkeletonScroll(child: ChannelTilesSkeleton(count: 3)),
                error: (error, _) => ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(mySubscribedChannelsProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.pickChannelEmpty),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final channel in items)
                        ListTile(
                          leading: ChannelAvatar(
                            name: channel.name,
                            seed: channel.id,
                          ),
                          title: Text(
                            channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.of(
                            context,
                          ).pop(PickedChannel(channel.slug)),
                        ),
                    ],
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(l10n.pickChannelOther),
              onTap: () => Navigator.of(context).pop(const PickedSearch()),
            ),
          ],
        ),
      ),
    );
  }
}
