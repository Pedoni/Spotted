import 'package:flutter/material.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/events/domain/event_validators.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// I valori di un evento nel modulo.
typedef EventFormValues = ({
  String title,
  String description,
  String? location,
  DateTime startsAt,
  DateTime? endsAt,
});

/// Il modulo di un evento (titolo, descrizione, luogo, inizio e fine), uguale
/// per crearlo e modificarlo. Chi lo usa decide cosa fare con i valori
/// ([onSubmit]) e mostra lo stato ([busy], [error]). Con [requireFutureStart]
/// (la creazione) l'inizio non può essere già passato; modificando sì, per
/// correggere un evento finito.
class EventForm extends StatefulWidget {
  const EventForm({
    required this.submitLabel,
    required this.onSubmit,
    this.requireFutureStart = false,
    this.initialTitle = '',
    this.initialDescription = '',
    this.initialLocation = '',
    this.initialStartsAt,
    this.initialEndsAt,
    this.channelName,
    this.busy = false,
    this.error,
    super.key,
  });

  final String submitLabel;
  final void Function(EventFormValues values) onSubmit;
  final bool requireFutureStart;
  final String initialTitle;
  final String initialDescription;
  final String initialLocation;
  final DateTime? initialStartsAt;
  final DateTime? initialEndsAt;

  /// Il canale a cui appartiene l'evento, mostrato sopra il modulo.
  final String? channelName;
  final bool busy;
  final Object? error;

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initialTitle);
  late final _description = TextEditingController(
    text: widget.initialDescription,
  );
  late final _location = TextEditingController(text: widget.initialLocation);
  late DateTime? _startsAt = widget.initialStartsAt;
  late DateTime? _endsAt = widget.initialEndsAt;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit((
      title: _title.text,
      description: _description.text,
      location: _location.text,
      startsAt: _startsAt!,
      endsAt: _endsAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.channelName != null) ...[
            Text(widget.channelName!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
          ],
          Text(l10n.eventPublicNote, style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          TextFormField(
            controller: _title,
            maxLength: EventValidators.maxTitleLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.eventTitleLabel),
            validator: (v) => EventValidators.isValidTitle(v ?? '')
                ? null
                : l10n.validationRequired,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            minLines: 4,
            maxLines: 10,
            maxLength: EventValidators.maxDescriptionLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.eventDescriptionLabel,
              alignLabelWithHint: true,
            ),
            validator: (v) => EventValidators.isValidDescription(v ?? '')
                ? null
                : l10n.validationRequired,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _location,
            maxLength: EventValidators.maxLocationLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.eventLocationLabel),
          ),
          const SizedBox(height: 16),
          _DateTimeField(
            label: l10n.eventStartsLabel,
            value: _startsAt,
            // Creando, non si parte dal passato; modificando sì.
            firstDate: widget.requireFutureStart ? null : DateTime(2020),
            fallback: _defaultStart(),
            onChanged: (v) => setState(() => _startsAt = v),
            validator: (v) {
              if (v == null) return l10n.validationRequired;
              if (widget.requireFutureStart && v.isBefore(DateTime.now())) {
                return l10n.eventStartInPast;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _DateTimeField(
            label: l10n.eventEndsLabel,
            value: _endsAt,
            firstDate: _startsAt,
            fallback: _startsAt ?? _defaultStart(),
            clearTooltip: l10n.eventClearEnd,
            onChanged: (v) => setState(() => _endsAt = v),
            validator: (v) {
              final start = _startsAt;
              if (v != null &&
                  start != null &&
                  !EventValidators.areValidDates(start, v)) {
                return l10n.eventEndBeforeStart;
              }
              return null;
            },
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 16),
            Text(
              failureMessage(l10n, widget.error!),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.busy ? null : _submit,
            child: widget.busy
                ? const InlineProgress()
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }

  /// Da dove parte il selettore dell'inizio: domani alle 18.
  DateTime _defaultStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 18);
  }
}

/// Un campo che mostra un momento (data e ora) e lo fa scegliere con il
/// selettore della data e poi quello dell'ora. Con `clearTooltip` il valore si
/// può togliere (campo facoltativo).
class _DateTimeField extends FormField<DateTime> {
  _DateTimeField({
    required String label,
    required DateTime? value,
    required DateTime fallback,
    required ValueChanged<DateTime?> onChanged,
    required String? Function(DateTime?) validator,
    DateTime? firstDate,
    String? clearTooltip,
  }) : super(
         initialValue: value,
         validator: validator,
         builder: (state) {
           // Il campo segue il valore che gli dà il modulo.
           if (state.value != value) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if (state.mounted) state.didChange(value);
             });
           }
           final context = state.context;
           Future<void> pick() async {
             final now = DateTime.now();
             final initial = value ?? fallback;
             final first = firstDate ?? DateTime(now.year, now.month, now.day);
             final date = await showDatePicker(
               context: context,
               initialDate: initial.isBefore(first) ? first : initial,
               firstDate: first.isBefore(DateTime(2020))
                   ? DateTime(2020)
                   : first,
               lastDate: DateTime(now.year + 5, 12, 31),
             );
             if (date == null || !context.mounted) return;
             final time = await showTimePicker(
               context: context,
               initialTime: TimeOfDay.fromDateTime(initial),
               // Ora a 24 ore, come in tutta l'app.
               builder: (context, child) => MediaQuery(
                 data: MediaQuery.of(
                   context,
                 ).copyWith(alwaysUse24HourFormat: true),
                 child: child!,
               ),
             );
             if (time == null) return;
             final picked = DateTime(
               date.year,
               date.month,
               date.day,
               time.hour,
               time.minute,
             );
             state.didChange(picked);
             onChanged(picked);
           }

           return InkWell(
             borderRadius: BorderRadius.circular(20),
             onTap: pick,
             child: InputDecorator(
               isEmpty: value == null,
               decoration: InputDecoration(
                 labelText: label,
                 errorText: state.errorText,
                 suffixIcon: value != null && clearTooltip != null
                     ? IconButton(
                         tooltip: clearTooltip,
                         icon: const Icon(Icons.close_rounded),
                         onPressed: () {
                           state.didChange(null);
                           onChanged(null);
                         },
                       )
                     : const Icon(Icons.event_rounded),
               ),
               child: value == null
                   ? null
                   : Text(formatDateTime(context, value)),
             ),
           );
         },
       );
}
