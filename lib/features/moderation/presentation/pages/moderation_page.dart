import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/moderation/domain/entities/moderation_status.dart';
import 'package:spotted/features/moderation/presentation/providers/hidden_spots_feed.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/reports/presentation/widgets/channel_reports_list.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Gli spot nascosti di un canale, da ripristinare. Solo per il proprietario:
/// per chiunque altro il database risponde "permesso negato".
class ModerationPage extends ConsumerWidget {
  const ModerationPage({required this.slug, super.key});

  final String slug;

  Future<void> _restore(BuildContext context, WidgetRef ref, Spot spot) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(spotModerationProvider.notifier)
          .setStatus(spot, ModerationStatus.published);
      messenger.showSnackBar(SnackBar(content: Text(l10n.spotRestored)));
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final channel = ref.watch(channelDetailProvider(slug));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.moderationTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.reportsTab),
              Tab(text: l10n.moderationHiddenSpots),
            ],
          ),
        ),
        body: channel.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(channelDetailProvider(slug)),
          ),
          data: (channel) => TabBarView(
            children: [
              ChannelReportsList(channelId: channel.id),
              _HiddenSpotsList(
                channelId: channel.id,
                onRestore: (spot) => unawaited(_restore(context, ref, spot)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HiddenSpotsList extends ConsumerWidget {
  const _HiddenSpotsList({required this.channelId, required this.onRestore});

  final String channelId;
  final void Function(Spot spot) onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = hiddenSpotsFeedProvider(channelId);
    final feed = ref.watch(provider);

    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
      data: (paged) {
        if (paged.items.isEmpty) {
          return Center(child: Text(l10n.noHiddenSpots));
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future),
          child: ListView.builder(
            itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < paged.items.length) {
                final spot = paged.items[index];
                return SpotCard(
                  spot: spot,
                  onTap: () => context.push(AppRoutes.spotPath(spot.id)),
                  trailing: TextButton(
                    onPressed: () => onRestore(spot),
                    child: Text(l10n.restoreSpot),
                  ),
                );
              }
              if (paged.loadMoreFailed) {
                return ListTile(
                  title: Text(l10n.loadMoreSpotsError),
                  trailing: TextButton(
                    onPressed: () =>
                        unawaited(ref.read(provider.notifier).loadMore()),
                    child: Text(l10n.retry),
                  ),
                );
              }
              // L'ultimo elemento è il caricamento: quando compare a schermo
              // si chiede la pagina successiva.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  unawaited(ref.read(provider.notifier).loadMore());
                }
              });
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        );
      },
    );
  }
}
