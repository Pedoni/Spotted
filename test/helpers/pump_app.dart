import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/app.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/features/auth/domain/entities/app_user.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/comments/presentation/providers/comments_providers.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/profile/presentation/providers/profile_providers.dart';
import 'package:spotted/features/reports/presentation/providers/reports_providers.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';
import 'package:spotted/features/subscriptions/presentation/providers/subscriptions_providers.dart';
import 'package:spotted/features/topics/presentation/providers/topics_providers.dart';

import 'fake_auth_repository.dart';
import 'fake_repositories.dart';

/// Avvia l'app con repository finti. Per default l'utente è già loggato.
Future<void> pumpApp(
  WidgetTester tester, {
  FakeAuthRepository? auth,
  FakeChannelsRepository? channels,
  FakeTopicsRepository? topics,
  FakeProfileRepository? profile,
  FakeSubscriptionsRepository? subscriptions,
  FakeSpotsRepository? spots,
  FakeCommentsRepository? comments,
  FakeModerationRepository? moderation,
  FakeReportsRepository? reports,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noRetry,
      overrides: [
        authRepositoryProvider.overrideWithValue(
          auth ?? FakeAuthRepository(user: loggedInUser),
        ),
        channelsRepositoryProvider.overrideWithValue(
          channels ?? FakeChannelsRepository(),
        ),
        topicsRepositoryProvider.overrideWithValue(
          topics ?? FakeTopicsRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(
          profile ?? FakeProfileRepository(),
        ),
        subscriptionsRepositoryProvider.overrideWithValue(
          subscriptions ?? FakeSubscriptionsRepository(),
        ),
        spotsRepositoryProvider.overrideWithValue(
          spots ?? FakeSpotsRepository(),
        ),
        commentsRepositoryProvider.overrideWithValue(
          comments ?? FakeCommentsRepository(),
        ),
        moderationRepositoryProvider.overrideWithValue(
          moderation ?? FakeModerationRepository(),
        ),
        reportsRepositoryProvider.overrideWithValue(
          reports ?? FakeReportsRepository(),
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

const loggedInUser = AppUser(id: '1', email: 'a@b.it');
