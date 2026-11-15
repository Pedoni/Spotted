import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/features/channels/presentation/providers/create_channel_controller.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_form.dart';
import 'package:spotted/l10n/app_localizations.dart';

class CreateChannelPage extends ConsumerWidget {
  const CreateChannelPage({super.key});

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    ChannelFormValues values,
  ) async {
    final channel = await ref
        .read(createChannelControllerProvider.notifier)
        .submit(
          name: values.name,
          description: values.description,
          municipalityId: values.municipality?.istatCode,
          topicId: values.topicId,
        );
    if (channel != null && context.mounted) {
      // Sostituisce il form con la pagina del canale appena creato.
      context.pushReplacement(AppRoutes.channelPath(channel.slug));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(createChannelControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createChannelTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: ChannelForm(
                submitLabel: l10n.createChannelButton,
                busy: state.isLoading,
                error: state.hasError ? state.error : null,
                onSubmit: (values) => _submit(context, ref, values),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
