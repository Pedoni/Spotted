import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';
import 'package:spotted/features/spots/presentation/providers/create_spot_controller.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_skeletons.dart';
import 'package:spotted/features/tags/presentation/widgets/tag_picker.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Form per scrivere uno spot (anonimo) nel canale [slug]. Un utente lo invia e
/// aspetta l'approvazione del proprietario; il proprietario sceglie i tag e lo
/// pubblica subito.
class CreateSpotPage extends ConsumerStatefulWidget {
  const CreateSpotPage({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<CreateSpotPage> createState() => _CreateSpotPageState();
}

class _CreateSpotPageState extends ConsumerState<CreateSpotPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();

  /// I tag scelti: solo il proprietario li sceglie.
  var _tags = <String>[];

  /// Il proprietario ha provato a pubblicare senza tag.
  var _tagsMissing = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit(String channelId, {required bool owner}) async {
    final valid = _formKey.currentState!.validate();
    final tagsValid = !owner || SpotValidators.isValidTagCount(_tags.length);
    setState(() => _tagsMissing = !tagsValid);
    if (!valid || !tagsValid) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final spot = await ref
        .read(createSpotControllerProvider.notifier)
        .submit(
          channelId: channelId,
          title: _title.text,
          content: _content.text,
          tags: owner ? _tags : null,
        );
    if (spot != null && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(owner ? l10n.spotPublished : l10n.spotSubmitted),
        ),
      );
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channel = ref.watch(channelDetailProvider(widget.slug));
    final state = ref.watch(createSpotControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.publishSpot)),
      body: channel.when(
        loading: () => const SkeletonScroll(child: SpotFormSkeleton()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(channelDetailProvider(widget.slug)),
        ),
        data: (channel) {
          // Finché non si sa se sei il proprietario vale il caso comune.
          final owner =
              ref.watch(isChannelOwnerProvider(channel.id)).value ?? false;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          channel.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.spotAnonymousNote,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (!owner) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.spotApprovalNote,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _title,
                          maxLength: SpotValidators.maxTitleLength,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.spotTitleLabel,
                          ),
                          validator: (v) => SpotValidators.isValidTitle(v ?? '')
                              ? null
                              : l10n.validationRequired,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _content,
                          minLines: 5,
                          maxLines: 12,
                          maxLength: SpotValidators.maxContentLength,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: l10n.spotContentLabel,
                            alignLabelWithHint: true,
                          ),
                          validator: (v) =>
                              SpotValidators.isValidContent(v ?? '')
                              ? null
                              : l10n.validationRequired,
                        ),
                        if (owner) ...[
                          const SizedBox(height: 24),
                          Text(
                            l10n.spotTagsTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TagPicker(
                            channelId: channel.id,
                            selected: _tags,
                            onChanged: (tags) => setState(() {
                              _tags = tags;
                              _tagsMissing = false;
                            }),
                          ),
                          if (_tagsMissing) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.tagsRequired,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
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
                          onPressed: state.isLoading
                              ? null
                              : () => _submit(channel.id, owner: owner),
                          child: state.isLoading
                              ? const InlineProgress()
                              : Text(
                                  owner
                                      ? l10n.publishSpotButton
                                      : l10n.sendSpotButton,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
