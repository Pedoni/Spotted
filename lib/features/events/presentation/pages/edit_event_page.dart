import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/events/domain/entities/channel_event.dart';
import 'package:spotted/features/events/presentation/providers/event_actions.dart';
import 'package:spotted/features/events/presentation/providers/events_providers.dart';
import 'package:spotted/features/events/presentation/widgets/event_form.dart';
import 'package:spotted/features/events/presentation/widgets/event_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Modifica di un evento (solo il proprietario: per gli altri il database
/// risponde con un errore di permessi).
class EditEventPage extends ConsumerStatefulWidget {
  const EditEventPage({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends ConsumerState<EditEventPage> {
  bool _busy = false;
  Object? _error;

  Future<void> _submit(ChannelEvent event, EventFormValues values) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final actions = ref.read(eventActionsProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await actions.update(
        eventId: event.id,
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
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventUpdated)));
    if (mounted) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = ref.watch(eventDetailProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editEventTitle)),
      body: event.when(
        loading: () => const SkeletonScroll(child: EventFormSkeleton()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(eventDetailProvider(widget.eventId)),
        ),
        data: (event) => SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: EventForm(
                  channelName: event.channelName,
                  initialTitle: event.title,
                  initialDescription: event.description,
                  initialLocation: event.location ?? '',
                  initialStartsAt: event.startsAt.toLocal(),
                  initialEndsAt: event.endsAt?.toLocal(),
                  submitLabel: l10n.saveEventButton,
                  busy: _busy,
                  error: _error,
                  onSubmit: (values) => _submit(event, values),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
