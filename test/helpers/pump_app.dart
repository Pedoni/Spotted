import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotted/app.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/core/theme/theme_mode_provider.dart';
import 'package:spotted/features/auth/domain/entities/app_user.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';
import 'package:spotted/features/chat/presentation/providers/chat_providers.dart';
import 'package:spotted/features/comments/presentation/providers/comments_providers.dart';
import 'package:spotted/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:spotted/features/municipalities/presentation/providers/municipalities_providers.dart';
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
  FakeChatRepository? chat,
  FakeMunicipalitiesRepository? municipalities,
  Duration? chatPollInterval,
  Map<String, Object> preferences = const {},

  /// Dimensione dello schermo: le liste costruiscono solo ciò che si vede, per
  /// le pagine lunghe (il profilo) serve uno schermo alto.
  Size? screenSize,

  /// Se è `false` non aspetta che tutto si fermi: serve quando la schermata
  /// resta in caricamento, perché lo scheletro anima di continuo.
  bool settle = true,
}) async {
  if (screenSize != null) {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  SharedPreferences.setMockInitialValues(preferences);
  final sharedPreferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      retry: noRetry,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
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
        chatRepositoryProvider.overrideWithValue(chat ?? FakeChatRepository()),
        municipalitiesRepositoryProvider.overrideWithValue(
          municipalities ?? FakeMunicipalitiesRepository(),
        ),
        // Senza polling di default: i timer periodici lascerebbero il test in
        // attesa.
        chatPollIntervalProvider.overrideWithValue(chatPollInterval),
      ],
      child: const App(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Schermo abbastanza alto da mostrare tutto il profilo.
const tallScreen = Size(800, 2000);

const loggedInUser = AppUser(id: '1', email: 'a@b.it');
