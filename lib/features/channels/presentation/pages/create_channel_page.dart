import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/channels/domain/channel_validators.dart';
import 'package:spotted/features/channels/presentation/providers/create_channel_controller.dart';
import 'package:spotted/features/municipalities/presentation/widgets/municipality_field.dart';
import 'package:spotted/features/topics/presentation/providers/topics_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

class CreateChannelPage extends ConsumerStatefulWidget {
  const CreateChannelPage({super.key});

  @override
  ConsumerState<CreateChannelPage> createState() => _CreateChannelPageState();
}

class _CreateChannelPageState extends ConsumerState<CreateChannelPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String? _topicId;
  MunicipalityChoice? _municipality;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final channel = await ref
        .read(createChannelControllerProvider.notifier)
        .submit(
          name: _name.text,
          description: _description.text,
          municipalityId: _municipality?.istatCode,
          topicId: _topicId,
        );
    if (channel != null && mounted) {
      // Sostituisce il form con la pagina del canale appena creato.
      context.pushReplacement(AppRoutes.channelPath(channel.slug));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(createChannelControllerProvider);
    final topics = ref.watch(topicsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createChannelTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.channelNameLabel,
                      ),
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
                      decoration: InputDecoration(
                        labelText: l10n.channelTopicLabel,
                      ),
                      items: [
                        DropdownMenuItem(child: Text(l10n.noTopic)),
                        for (final topic in topics)
                          DropdownMenuItem(
                            value: topic.id,
                            child: Text(topic.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _topicId = value),
                    ),
                    const SizedBox(height: 16),
                    MunicipalityField(
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
                      validator: (v) =>
                          ChannelValidators.isValidDescription(v ?? '')
                          ? null
                          : l10n.validationTooLong(
                              ChannelValidators.maxDescriptionLength,
                            ),
                    ),
                    if (state.hasError) ...[
                      const SizedBox(height: 16),
                      Text(
                        failureMessage(l10n, state.error!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: state.isLoading ? null : _submit,
                      child: state.isLoading
                          ? const InlineProgress()
                          : Text(l10n.createChannelButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
