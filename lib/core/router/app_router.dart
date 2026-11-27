import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/router/app_shell.dart';
import 'package:spotted/features/admin/presentation/pages/admin_reports_page.dart';
import 'package:spotted/features/auth/presentation/pages/login_page.dart';
import 'package:spotted/features/auth/presentation/pages/sign_up_page.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/channels/presentation/pages/channel_detail_page.dart';
import 'package:spotted/features/channels/presentation/pages/channels_page.dart';
import 'package:spotted/features/channels/presentation/pages/create_channel_page.dart';
import 'package:spotted/features/channels/presentation/pages/edit_channel_page.dart';
import 'package:spotted/features/chat/presentation/pages/chat_page.dart';
import 'package:spotted/features/chat/presentation/pages/chats_page.dart';
import 'package:spotted/features/events/presentation/pages/create_event_page.dart';
import 'package:spotted/features/events/presentation/pages/edit_event_page.dart';
import 'package:spotted/features/events/presentation/pages/event_detail_page.dart';
import 'package:spotted/features/events/presentation/pages/upcoming_events_page.dart';
import 'package:spotted/features/home/presentation/home_page.dart';
import 'package:spotted/features/moderation/presentation/pages/moderation_page.dart';
import 'package:spotted/features/news/presentation/pages/create_news_page.dart';
import 'package:spotted/features/news/presentation/pages/edit_news_page.dart';
import 'package:spotted/features/news/presentation/pages/latest_news_page.dart';
import 'package:spotted/features/news/presentation/pages/news_detail_page.dart';
import 'package:spotted/features/profile/presentation/pages/about_page.dart';
import 'package:spotted/features/profile/presentation/pages/change_email_page.dart';
import 'package:spotted/features/profile/presentation/pages/change_password_page.dart';
import 'package:spotted/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:spotted/features/profile/presentation/pages/profile_page.dart';
import 'package:spotted/features/spots/presentation/pages/create_spot_page.dart';
import 'package:spotted/features/spots/presentation/pages/my_spots_page.dart';
import 'package:spotted/features/spots/presentation/pages/spot_detail_page.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Ri-valuta il redirect quando si entra o si esce (cambia l'utente), non a
  // ogni modifica dei suoi dati: cambiare email o password aggiorna l'utente,
  // e un `refresh` rifà il percorso dall'indirizzo e perde le pagine aperte
  // sotto (si tornerebbe alla Home invece che al Profilo).
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authStateProvider, (previous, next) {
      if (previous?.value?.id != next.value?.id) refresh.value++;
    })
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
        path: AppRoutes.newsNew,
        builder: (context, state) =>
            CreateNewsPage(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: AppRoutes.eventNew,
        builder: (context, state) =>
            CreateEventPage(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: AppRoutes.eventDetail,
        builder: (context, state) =>
            EventDetailPage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.eventEdit,
        builder: (context, state) =>
            EditEventPage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.upcomingEvents,
        builder: (context, state) => const UpcomingEventsPage(),
      ),
      GoRoute(
        path: AppRoutes.latestNews,
        builder: (context, state) => const LatestNewsPage(),
      ),
      GoRoute(
        path: AppRoutes.newsDetail,
        builder: (context, state) =>
            NewsDetailPage(newsId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.newsEdit,
        builder: (context, state) =>
            EditNewsPage(newsId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.channelEdit,
        builder: (context, state) =>
            EditChannelPage(slug: state.pathParameters['slug']!),
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
        path: AppRoutes.adminReports,
        builder: (context, state) => const AdminReportsPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.changeEmail,
        builder: (context, state) => const ChangeEmailPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutPage(),
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
