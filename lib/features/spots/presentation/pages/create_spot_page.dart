import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';
import 'package:spotted/features/spots/presentation/providers/create_spot_controller.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Form per pubblicare uno spot (anonimo) nel canale [slug].
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

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit(String channelId) async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final spot = await ref
        .read(createSpotControllerProvider.notifier)
        .submit(
          channelId: channelId,
          title: _title.text,
          content: _content.text,
        );
    if (spot != null && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.spotPublished)));
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
        data: (channel) => SafeArea(
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
                        validator: (v) => SpotValidators.isValidContent(v ?? '')
                            ? null
                            : l10n.validationRequired,
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
                        onPressed: state.isLoading
                            ? null
                            : () => _submit(channel.id),
                        child: state.isLoading
                            ? const InlineProgress()
                            : Text(l10n.publishSpotButton),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
