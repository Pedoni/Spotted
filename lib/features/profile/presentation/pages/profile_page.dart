import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/core/widgets/user_avatar.dart';
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

  List<Widget> _content(
    BuildContext context, {
    required Profile profile,
    required String? email,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return [
      Center(child: UserAvatar(username: profile.username, size: 96)),
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
      const SizedBox(height: 24),
      ListTile(
        leading: const Icon(Icons.edit_note),
        title: Text(l10n.mySpotsTitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.mySpots),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider);
    final email = ref.watch(authStateProvider).value?.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsOpen,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: profile.when(
        loading: () => Skeleton(
          child: ListView(
            padding: const EdgeInsets.all(24),
            physics: const NeverScrollableScrollPhysics(),
            children: _content(
              context,
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
          children: _content(context, profile: profile, email: email),
        ),
      ),
    );
  }
}
