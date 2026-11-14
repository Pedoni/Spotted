import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/features/spots/presentation/providers/my_spots_feed.dart';
import 'package:spotted/features/spots/presentation/widgets/channel_picker_sheet.dart';
import 'package:spotted/features/spots/presentation/widgets/my_spots_carousel.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Home: i miei spot in un carosello e il pulsante per pubblicarne uno.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _publish(BuildContext context) async {
    final pick = await showChannelPickerSheet(context);
    if (pick == null || !context.mounted) return;
    switch (pick) {
      case PickedChannel(:final slug):
        await context.push(AppRoutes.spotNewPath(slug));
      case PickedSearch():
        context.go(AppRoutes.channels);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      floatingActionButton: FloatingActionButton.extended(
        // Un tag diverso da quello di Canali: le schede stanno nello stesso
        // stack e due pulsanti con il tag di default fanno fallire le
        // transizioni.
        heroTag: 'home-publish',
        onPressed: () => unawaited(_publish(context)),
        icon: const Icon(Icons.edit_outlined),
        label: Text(l10n.publishSpotButton),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(mySpotsFeedProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 88),
          children: const [MySpotsSection()],
        ),
      ),
    );
  }
}
