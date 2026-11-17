import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/news/presentation/providers/news_actions.dart';
import 'package:spotted/features/news/presentation/widgets/news_form.dart';
import 'package:spotted/features/news/presentation/widgets/news_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Form per pubblicare una news nel canale [slug] (solo il proprietario: per
/// gli altri il database risponde con un errore di permessi).
class CreateNewsPage extends ConsumerStatefulWidget {
  const CreateNewsPage({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<CreateNewsPage> createState() => _CreateNewsPageState();
}

class _CreateNewsPageState extends ConsumerState<CreateNewsPage> {
  bool _busy = false;
  Object? _error;

  Future<void> _submit(String channelId, String title, String body) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final actions = ref.read(newsActionsProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await actions.create(channelId: channelId, title: title, body: body);
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error;
        });
      }
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.newsPublished)));
    if (mounted) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channel = ref.watch(channelDetailProvider(widget.slug));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createNewsTitle)),
      body: channel.when(
        loading: () => const SkeletonScroll(child: NewsFormSkeleton()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(channelDetailProvider(widget.slug)),
        ),
        data: (channel) => SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: NewsForm(
                  channelName: channel.name,
                  submitLabel: l10n.publishNewsButton,
                  busy: _busy,
                  error: _error,
                  onSubmit: (title, body) => _submit(channel.id, title, body),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
