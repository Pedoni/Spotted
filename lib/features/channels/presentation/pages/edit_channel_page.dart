import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/presentation/providers/channel_actions.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_form.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Modifica di un canale dell'utente: nome, argomento, comune e descrizione.
/// L'indirizzo (lo slug) non cambia.
class EditChannelPage extends ConsumerStatefulWidget {
  const EditChannelPage({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<EditChannelPage> createState() => _EditChannelPageState();
}

class _EditChannelPageState extends ConsumerState<EditChannelPage> {
  bool _busy = false;
  Object? _error;

  Future<void> _submit(Channel channel, ChannelFormValues values) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(channelActionsProvider.notifier)
          .update(
            channel: channel,
            name: values.name,
            description: values.description,
            topicId: values.topicId,
            municipalityId: values.municipality?.istatCode,
          );
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error;
        });
      }
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.channelUpdated)));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channel = ref.watch(channelDetailProvider(widget.slug));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editChannelTitle)),
      body: channel.when(
        loading: () => const SkeletonScroll(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: ChannelFormSkeleton(),
          ),
        ),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(channelDetailProvider(widget.slug)),
        ),
        data: (channel) => SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ChannelForm(
                  initial: channel,
                  submitLabel: l10n.saveChannelButton,
                  busy: _busy,
                  error: _error,
                  onSubmit: (values) => _submit(channel, values),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
