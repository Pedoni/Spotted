import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/features/auth/presentation/providers/auth_controllers.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/profile/presentation/providers/profile_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider);
    final email = ref.watch(authStateProvider).value?.email;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
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
              leading: const Icon(Icons.logout),
              title: Text(l10n.logout),
              onTap: () =>
                  ref.read(signOutControllerProvider.notifier).submit(),
            ),
          ],
        ),
      ),
    );
  }
}
