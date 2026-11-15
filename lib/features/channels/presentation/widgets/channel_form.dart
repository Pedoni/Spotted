import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/channels/domain/channel_validators.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/municipalities/presentation/widgets/municipality_field.dart';
import 'package:spotted/features/topics/presentation/providers/topics_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// I valori scritti nel modulo del canale.
class ChannelFormValues {
  const ChannelFormValues({
    required this.name,
    required this.description,
    required this.topicId,
    required this.municipality,
  });

  final String name;
  final String description;
  final String? topicId;
  final MunicipalityChoice? municipality;
}

/// Il modulo per creare o modificare un canale: nome, argomento, comune e
/// descrizione. Con [initial] parte dai valori del canale.
class ChannelForm extends ConsumerStatefulWidget {
  const ChannelForm({
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
    this.busy = false,
    this.error,
    super.key,
  });

  final Channel? initial;
  final String submitLabel;

  /// Mentre l'invio è in corso il pulsante è fermo e mostra l'avanzamento.
  final bool busy;
  final Object? error;
  final ValueChanged<ChannelFormValues> onSubmit;

  @override
  ConsumerState<ChannelForm> createState() => _ChannelFormState();
}

class _ChannelFormState extends ConsumerState<ChannelForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late String? _topicId = widget.initial?.topicId;
  late MunicipalityChoice? _municipality = _initialMunicipality();

  MunicipalityChoice? _initialMunicipality() {
    final channel = widget.initial;
    final id = channel?.municipalityId;
    if (channel == null || id == null) return null;
    return MunicipalityChoice(istatCode: id, label: channel.place ?? id);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      ChannelFormValues(
        name: _name.text,
        description: _description.text,
        topicId: _topicId,
        municipality: _municipality,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topics = ref.watch(topicsProvider).value ?? const [];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.channelNameLabel),
            validator: (v) => ChannelValidators.isValidName(v ?? '')
                ? null
                : l10n.validationChannelName(
                    ChannelValidators.minNameLength,
                    ChannelValidators.maxNameLength,
                  ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _topicId,
            decoration: InputDecoration(labelText: l10n.channelTopicLabel),
            items: [
              DropdownMenuItem(child: Text(l10n.noTopic)),
              for (final topic in topics)
                DropdownMenuItem(value: topic.id, child: Text(topic.name)),
            ],
            onChanged: (value) => setState(() => _topicId = value),
          ),
          const SizedBox(height: 16),
          MunicipalityField(
            initialValue: _municipality,
            onChanged: (choice) => _municipality = choice,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.channelDescriptionLabel,
              alignLabelWithHint: true,
            ),
            validator: (v) => ChannelValidators.isValidDescription(v ?? '')
                ? null
                : l10n.validationTooLong(
                    ChannelValidators.maxDescriptionLength,
                  ),
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 16),
            Text(
              failureMessage(l10n, widget.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
}
