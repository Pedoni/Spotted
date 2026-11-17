import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/features/news/presentation/providers/followed_news_feed.dart';
import 'package:spotted/features/news/presentation/widgets/latest_news_section.dart';
import 'package:spotted/features/spots/presentation/providers/my_spots_feed.dart';
import 'package:spotted/features/spots/presentation/widgets/my_spots_carousel.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Home: i miei spot e le ultime news dei canali seguiti, in due caroselli.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Ricarica le sezioni. Gli errori li mostra ogni sezione, non il gesto di
  /// ricarica.
  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref
          .refresh(mySpotsFeedProvider.future)
          .then((_) {}, onError: (Object _) {}),
      ref
          .refresh(followedNewsFeedProvider.future)
          .then((_) {}, onError: (Object _) {}),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: const [MySpotsSection(), LatestNewsSection()],
        ),
      ),
    );
  }
}
