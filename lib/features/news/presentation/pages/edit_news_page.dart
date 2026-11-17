import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/presentation/providers/news_actions.dart';
import 'package:spotted/features/news/presentation/providers/news_providers.dart';
import 'package:spotted/features/news/presentation/widgets/news_form.dart';
import 'package:spotted/features/news/presentation/widgets/news_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Modifica di una news (solo il proprietario: per gli altri il database
/// risponde con un errore di permessi).
class EditNewsPage extends ConsumerStatefulWidget {
  const EditNewsPage({required this.newsId, super.key});

  final String newsId;

  @override
  ConsumerState<EditNewsPage> createState() => _EditNewsPageState();
}

class _EditNewsPageState extends ConsumerState<EditNewsPage> {
  bool _busy = false;
  Object? _error;

  Future<void> _submit(ChannelNews news, String title, String body) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final actions = ref.read(newsActionsProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await actions.update(newsId: news.id, title: title, body: body);
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error;
        });
      }
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.newsUpdated)));
    if (mounted) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final news = ref.watch(newsDetailProvider(widget.newsId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editNewsTitle)),
      body: news.when(
        loading: () => const SkeletonScroll(child: NewsFormSkeleton()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(newsDetailProvider(widget.newsId)),
        ),
        data: (news) => SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: NewsForm(
                  channelName: news.channelName,
                  initialTitle: news.title,
                  initialBody: news.body,
                  submitLabel: l10n.saveNewsButton,
                  busy: _busy,
                  error: _error,
                  onSubmit: (title, body) => _submit(news, title, body),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
