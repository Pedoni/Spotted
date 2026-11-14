import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/router/app_shell.dart';
import 'package:spotted/features/auth/presentation/pages/login_page.dart';
import 'package:spotted/features/auth/presentation/pages/sign_up_page.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/channels/presentation/pages/channel_detail_page.dart';
import 'package:spotted/features/channels/presentation/pages/channels_page.dart';
import 'package:spotted/features/channels/presentation/pages/create_channel_page.dart';
import 'package:spotted/features/chat/presentation/pages/chat_page.dart';
import 'package:spotted/features/chat/presentation/pages/chats_page.dart';
import 'package:spotted/features/home/presentation/home_page.dart';
import 'package:spotted/features/moderation/presentation/pages/moderation_page.dart';
import 'package:spotted/features/profile/presentation/pages/profile_page.dart';
import 'package:spotted/features/spots/presentation/pages/create_spot_page.dart';
import 'package:spotted/features/spots/presentation/pages/my_spots_page.dart';
import 'package:spotted/features/spots/presentation/pages/spot_detail_page.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Ri-valuta il redirect a ogni cambio di sessione.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authStateProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authRepositoryProvider).currentUser != null;
      final location = state.matchedLocation;
      final onAuthPage =
          location == AppRoutes.login || location == AppRoutes.signUp;

      if (!loggedIn && !onAuthPage) return AppRoutes.login;
      if (loggedIn && onAuthPage) return AppRoutes.home;
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.channels,
                builder: (context, state) => const ChannelsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chats,
                builder: (context, state) => const ChatsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      // Pagine a schermo intero, aperte con `push` sopra la barra in basso.
      GoRoute(
        path: AppRoutes.channelNew,
        builder: (context, state) => const CreateChannelPage(),
      ),
      GoRoute(
        path: AppRoutes.channelDetail,
        builder: (context, state) =>
            ChannelDetailPage(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: AppRoutes.spotNew,
        builder: (context, state) =>
            CreateSpotPage(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: AppRoutes.channelModeration,
        builder: (context, state) =>
            ModerationPage(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: AppRoutes.chatDetail,
        builder: (context, state) =>
            ChatPage(chatId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.spotDetail,
        builder: (context, state) =>
            SpotDetailPage(spotId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.mySpots,
        builder: (context, state) => const MySpotsPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpPage(),
      ),
    ],
  );
}
