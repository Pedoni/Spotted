import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/events/presentation/providers/event_actions.dart';
import 'package:spotted/features/events/presentation/widgets/event_form.dart';
import 'package:spotted/features/events/presentation/widgets/event_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Form per pubblicare un evento nel canale [slug] (solo il proprietario: per
/// gli altri il database risponde con un errore di permessi).
class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  bool _busy = false;
  Object? _error;

  Future<void> _submit(String channelId, EventFormValues values) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final actions = ref.read(eventActionsProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await actions.create(
        channelId: channelId,
        title: values.title,
        description: values.description,
        location: values.location,
        startsAt: values.startsAt,
        endsAt: values.endsAt,
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
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventPublished)));
    if (mounted) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channel = ref.watch(channelDetailProvider(widget.slug));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createEventTitle)),
      body: channel.when(
        loading: () => const SkeletonScroll(child: EventFormSkeleton()),
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
                child: EventForm(
                  channelName: channel.name,
                  submitLabel: l10n.publishEventButton,
                  requireFutureStart: true,
                  busy: _busy,
                  error: _error,
                  onSubmit: (values) => _submit(channel.id, values),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
