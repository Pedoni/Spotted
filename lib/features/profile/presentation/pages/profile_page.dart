import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/auth/presentation/providers/auth_controllers.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/presentation/providers/profile_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

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
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref, {
    required Profile profile,
    required String? email,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return [
      Text('@${profile.username}', style: theme.textTheme.headlineSmall),
      if (profile.fullName != null) Text(profile.fullName!),
      if (email != null && email.isNotEmpty) Text(email),
      const SizedBox(height: 24),
      ListTile(
        leading: const Icon(Icons.tag),
        title: Text(l10n.myChannelsTitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.myChannels),
      ),
      ListTile(
        leading: const Icon(Icons.edit_note),
        title: Text(l10n.mySpotsTitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.mySpots),
      ),
      ListTile(
        leading: const Icon(Icons.chat_bubble_outline),
        title: Text(l10n.myChatsTitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.chats),
      ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: Text(l10n.logout),
        onTap: () => unawaited(_confirmLogout(context, ref)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider);
    final email = ref.watch(authStateProvider).value?.email;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: profile.when(
        loading: () => Skeleton(
          child: ListView(
            padding: const EdgeInsets.all(24),
            physics: const NeverScrollableScrollPhysics(),
            children: _content(
              context,
              ref,
              profile: _placeholder,
              email: 'email@esempio.it',
            ),
          ),
        ),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(24),
          children: _content(context, ref, profile: profile, email: email),
        ),
      ),
    );
  }
}
