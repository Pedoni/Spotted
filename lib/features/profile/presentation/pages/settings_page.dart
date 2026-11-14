import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/theme/theme_mode_provider.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/auth/presentation/providers/auth_controllers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Impostazioni: tema, account (password ed eliminazione in arrivo) e uscita.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Chiede conferma prima di uscire: un tocco per sbaglio non deve buttare
  /// fuori l'utente.
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(signOutControllerProvider.notifier).submit();
    // Se esce, il router porta all'accesso e questa pagina non c'è più. Se
    // fallisce l'utente resta loggato e deve saperlo.
    final error = ref.read(signOutControllerProvider).error;
    if (error != null && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeSettingProvider);
    final signingOut = ref.watch(signOutControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.settingsAppearance, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.themeLight),
              ),
              ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.themeSystem),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) => unawaited(
              ref
                  .read(themeModeSettingProvider.notifier)
                  .select(selection.first),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsAccount, style: theme.textTheme.titleMedium),
          // Per ora non fanno nulla: arrivano più avanti.
          ListTile(
            enabled: false,
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.changePassword),
            subtitle: Text(l10n.comingSoon),
          ),
          ListTile(
            enabled: false,
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.deleteProfile),
            subtitle: Text(l10n.comingSoon),
          ),
          ListTile(
            enabled: !signingOut,
            leading: signingOut
                ? const InlineProgress()
                : const Icon(Icons.logout),
            title: Text(l10n.logout),
            onTap: () => unawaited(_confirmLogout(context, ref)),
          ),
        ],
      ),
    );
  }
}
