import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/presentation/providers/news_actions.dart';
import 'package:spotted/features/news/presentation/providers/news_providers.dart';
import 'package:spotted/features/news/presentation/widgets/news_card.dart';
import 'package:spotted/features/news/presentation/widgets/news_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Una news per intero. Il proprietario del canale può modificarla o
/// eliminarla.
class NewsDetailPage extends ConsumerWidget {
  const NewsDetailPage({required this.newsId, super.key});

  final String newsId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final news = ref.watch(newsDetailProvider(newsId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newsTitle),
        actions: [
          if (news.value case final loaded?) _OwnerMenu(news: loaded),
        ],
      ),
      body: news.when(
        loading: () => const SkeletonScroll(child: NewsCardsSkeleton(count: 1)),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(newsDetailProvider(newsId)),
        ),
        data: (news) => SingleChildScrollView(
          child: NewsCard(
            news: news,
            showChannel: true,
            onChannelTap: () => unawaited(
              context.push(AppRoutes.channelPath(news.channelSlug)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modifica ed elimina: li vede solo il proprietario del canale.
class _OwnerMenu extends ConsumerWidget {
  const _OwnerMenu({required this.news});

  final ChannelNews news;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNewsTitle),
        content: Text(l10n.deleteNewsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Letto prima dell'attesa: la pagina può sparire mentre si aspetta.
    final actions = ref.read(newsActionsProvider.notifier);
    try {
      await actions.delete(news.id);
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.newsDeleted)));
    router.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isOwner = ref.watch(isChannelOwnerProvider(news.channelId)).value;
    if (isOwner != true) return const SizedBox.shrink();

    return PopupMenuButton<_NewsAction>(
      tooltip: l10n.newsActionsTooltip,
      onSelected: (action) {
        switch (action) {
          case _NewsAction.edit:
            unawaited(context.push(AppRoutes.newsEditPath(news.id)));
          case _NewsAction.delete:
            unawaited(_confirmDelete(context, ref));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _NewsAction.edit,
          child: Text(l10n.editNewsAction),
        ),
        PopupMenuItem(
          value: _NewsAction.delete,
          child: Text(l10n.deleteNewsAction),
        ),
      ],
    );
  }
}

enum _NewsAction { edit, delete }
