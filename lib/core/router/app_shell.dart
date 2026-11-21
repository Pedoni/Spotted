import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/features/chat/presentation/providers/chat_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Barra di navigazione in basso (Home, Canali, Chat, Profilo). L'icona Chat
/// mostra quante chat hanno messaggi non letti.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Se il numero non arriva non si mostra niente.
    final unread = ref.watch(unreadChatsProvider).value ?? 0;

    Widget chatIcon(IconData icon) => Badge.count(
      count: unread,
      isLabelVisible: unread > 0,
      maxCount: 99,
      backgroundColor: scheme.primary,
      textColor: scheme.onPrimary,
      child: Icon(icon),
    );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Toccare la tab già attiva torna alla sua pagina iniziale.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_rounded),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tag_rounded),
            selectedIcon: const Icon(Icons.tag_rounded),
            label: l10n.navChannels,
          ),
          NavigationDestination(
            icon: chatIcon(Icons.chat_bubble_outline_rounded),
            selectedIcon: chatIcon(Icons.chat_bubble_rounded),
            label: l10n.navChats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
