import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/theme/theme_mode_provider.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/core/widgets/user_avatar.dart';
import 'package:spotted/features/auth/presentation/providers/auth_controllers.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/presentation/providers/profile_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Profilo: foto e nome in alto, poi tema e account (password ed eliminazione
/// in arrivo) e uscita. I propri spot stanno nella Home.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  /// Dati finti per lo scheletro: le lunghezze danno la forma alle righe.
  static const _placeholder = Profile(
    id: 'skeleton',
    username: 'username',
    firstName: 'Nome',
    lastName: 'Cognome',
  );

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
    final error = await ref.read(signOutControllerProvider.notifier).submit();
    // Se esce, il router porta all'accesso e questa pagina non c'è più (e il
    // suo `ref` non si può più usare): da qui in poi si usa solo `error`. Se
    // fallisce l'utente resta loggato e deve saperlo.
    if (error != null && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    }
  }

  Widget _header(
    BuildContext context, {
    required Profile profile,
    required String? email,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        UserAvatar(username: profile.username, size: 96),
        const SizedBox(height: 16),
        Text(
          '@${profile.username}',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (profile.fullName != null)
          Text(profile.fullName!, textAlign: TextAlign.center),
        if (email != null && email.isNotEmpty)
          Text(email, textAlign: TextAlign.center),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(myProfileProvider);
    final email = ref.watch(authStateProvider).value?.email;
    final mode = ref.watch(themeModeSettingProvider);
    final signingOut = ref.watch(signOutControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Se il profilo non si carica il resto resta: l'uscita deve essere
          // sempre raggiungibile.
          profile.when(
            loading: () => Skeleton(
              child: _header(
                context,
                profile: _placeholder,
                email: 'email@esempio.it',
              ),
            ),
            error: (error, _) => Column(
              children: [
                Text(failureMessage(l10n, error), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ref.invalidate(myProfileProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
            data: (profile) => _header(context, profile: profile, email: email),
          ),
          const SizedBox(height: 32),
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
          // Queste voci ci sono ma per ora non fanno nulla: arrivano più
          // avanti.
          _SoonTile(
            icon: Icons.manage_accounts_rounded,
            title: l10n.editMyData,
          ),
          _SoonTile(icon: Icons.mail_outline_rounded, title: l10n.changeEmail),
          _SoonTile(
            icon: Icons.lock_outline_rounded,
            title: l10n.changePassword,
          ),
          _SoonTile(
            icon: Icons.notifications_none_rounded,
            title: l10n.notificationsSettings,
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsInfoSection, style: theme.textTheme.titleMedium),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(l10n.aboutApp),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => unawaited(context.push(AppRoutes.about)),
          ),
          _SoonTile(icon: Icons.privacy_tip_rounded, title: l10n.privacyPolicy),
          _SoonTile(icon: Icons.description_rounded, title: l10n.termsOfUse),
          const SizedBox(height: 24),
          _SoonTile(
            icon: Icons.delete_outline_rounded,
            title: l10n.deleteProfile,
          ),
          ListTile(
            enabled: !signingOut,
            leading: signingOut
                ? const InlineProgress()
                : const Icon(Icons.logout_rounded),
            title: Text(l10n.logout),
            onTap: () => unawaited(_confirmLogout(context, ref)),
          ),
        ],
      ),
    );
  }
}

/// Una voce che ancora non fa niente: spenta, con scritto "In arrivo".
class _SoonTile extends StatelessWidget {
  const _SoonTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: false,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(AppLocalizations.of(context).comingSoon),
    );
  }
}
