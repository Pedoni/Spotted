import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_skeletons.dart';
import 'package:spotted/features/chat/domain/entities/chat_message.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_skeletons.dart';
import 'package:spotted/features/comments/domain/entities/comment.dart';
import 'package:spotted/features/comments/presentation/widgets/comment_skeletons.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/reports/domain/entities/channel_report.dart';
import 'package:spotted/features/reports/presentation/widgets/report_skeletons.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_with_channel.dart';
import 'package:spotted/features/spots/presentation/pages/my_spots_page.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';
import 'package:spotted/features/spots/presentation/widgets/my_spots_carousel.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

// Repository che tengono ferma la lettura finché non si completa `hold`: la
// schermata resta in caricamento.

class HeldChannels extends FakeChannelsRepository {
  HeldChannels(
    this.hold, {
    super.channels,
    super.mine,
    this.list = false,
    this.detail = false,
    this.mineList = false,
  });

  final Completer<void> hold;
  final bool list;
  final bool detail;
  final bool mineList;

  @override
  Future<List<Channel>> getChannels({
    required int offset,
    required int limit,
    String? query,
    String? topicId,
  }) async {
    if (list) await hold.future;
    return super.getChannels(
      offset: offset,
      limit: limit,
      query: query,
      topicId: topicId,
    );
  }

  @override
  Future<Channel> getChannelBySlug(String slug) async {
    if (detail) await hold.future;
    return super.getChannelBySlug(slug);
  }

  @override
  Future<List<Channel>> getMyChannels() async {
    if (mineList) await hold.future;
    return super.getMyChannels();
  }
}

class HeldSubscriptions extends FakeSubscriptionsRepository {
  HeldSubscriptions(this.hold, {super.channels, super.subscribedIds});

  final Completer<void> hold;

  @override
  Future<List<Channel>> getMySubscribedChannels() async {
    await hold.future;
    return super.getMySubscribedChannels();
  }
}

class HeldProfile extends FakeProfileRepository {
  HeldProfile(this.hold);

  final Completer<void> hold;

  @override
  Future<Profile> getMyProfile() async {
    await hold.future;
    return super.getMyProfile();
  }
}

class HeldSpots extends FakeSpotsRepository {
  HeldSpots(
    this.hold, {
    super.spots,
    super.mine,
    this.detail = false,
  });

  final Completer<void> hold;
  final bool detail;

  @override
  Future<Spot> getSpot(String spotId) async {
    if (detail) await hold.future;
    return super.getSpot(spotId);
  }

  @override
  Future<List<SpotWithChannel>> getMySpots({
    required int offset,
    required int limit,
  }) async {
    if (!detail) await hold.future;
    return super.getMySpots(offset: offset, limit: limit);
  }
}

class HeldComments extends FakeCommentsRepository {
  HeldComments(this.hold, {super.comments});

  final Completer<void> hold;

  @override
  Future<List<Comment>> getSpotComments({
    required String spotId,
    required int offset,
    required int limit,
  }) async {
    await hold.future;
    return super.getSpotComments(spotId: spotId, offset: offset, limit: limit);
  }
}

class HeldChat extends FakeChatRepository {
  HeldChat(
    this.hold, {
    super.chats,
    super.messages,
    this.list = false,
    this.detail = false,
    this.messageList = false,
  });

  final Completer<void> hold;
  final bool list;
  final bool detail;
  final bool messageList;

  @override
  Future<List<ChatSummary>> getChats({
    required int offset,
    required int limit,
  }) async {
    if (list) await hold.future;
    return super.getChats(offset: offset, limit: limit);
  }

  @override
  Future<ChatSummary> getChat(String chatId) async {
    if (detail) await hold.future;
    return super.getChat(chatId);
  }

  @override
  Future<List<ChatMessage>> getMessages({
    required String chatId,
    required int offset,
    required int limit,
  }) async {
    if (messageList) await hold.future;
    return super.getMessages(chatId: chatId, offset: offset, limit: limit);
  }
}

class HeldReports extends FakeReportsRepository {
  HeldReports(this.hold, {super.reports});

  final Completer<void> hold;

  @override
  Future<List<ChannelReport>> getChannelReports({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    await hold.future;
    return super.getChannelReports(
      channelId: channelId,
      offset: offset,
      limit: limit,
    );
  }
}

class HeldModeration extends FakeModerationRepository {
  HeldModeration(
    this.hold, {
    super.ownedChannelIds,
    super.spotsRepository,
  });

  final Completer<void> hold;

  @override
  Future<List<Spot>> getHiddenSpots({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    await hold.future;
    return super.getHiddenSpots(
      channelId: channelId,
      offset: offset,
      limit: limit,
    );
  }
}

/// Va avanti di un secondo senza aspettare che lo scheletro smetta di animare.
Future<void> advance(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Si vede lo scheletro e non uno spinner.
void expectSkeleton(Finder skeleton) {
  expect(skeleton, findsWidgets);
  expect(find.byType(Skeleton), findsWidgets);
  expect(find.byType(CircularProgressIndicator), findsNothing);
}

/// I dati sono arrivati: sparisce lo scheletro.
Future<void> release(WidgetTester tester, Completer<void> hold) async {
  hold.complete();
  await tester.pumpAndSettle();
  expect(find.byType(Skeleton), findsNothing);
  expect(find.byType(CircularProgressIndicator), findsNothing);
}

Future<void> openChannelsTab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.tag_outlined));
  await advance(tester);
}

Future<void> openProfileTab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.person_outline));
  await advance(tester);
}

void main() {
  final channel = makeChannel(1, name: 'Spotted Pisa');

  testWidgets('Canali: l elenco', (tester) async {
    final hold = Completer<void>();
    await pumpApp(
      tester,
      channels: HeldChannels(hold, channels: [channel], list: true),
    );
    await openChannelsTab(tester);

    expectSkeleton(find.byType(ChannelTilesSkeleton));

    await release(tester, hold);
    expect(find.text('Spotted Pisa'), findsOneWidget);
  });

  testWidgets('Canale: intestazione e spot', (tester) async {
    final hold = Completer<void>();
    final channels = HeldChannels(hold, channels: [channel], detail: true);
    await pumpApp(tester, channels: channels);
    await openChannelsTab(tester);
    await tester.tap(find.text('Spotted Pisa'));
    await advance(tester);

    expectSkeleton(find.byType(ChannelHeaderSkeleton));
    expect(find.byType(SpotCardsSkeleton), findsOneWidget);

    await release(tester, hold);
  });

  testWidgets('I miei canali', (tester) async {
    final hold = Completer<void>();
    await pumpApp(
      tester,
      channels: HeldChannels(hold, mine: [channel], mineList: true),
    );
    await tester.tap(find.byIcon(Icons.tag_outlined));
    await advance(tester);
    await tester.tap(find.text('Miei'));
    await advance(tester);

    expectSkeleton(find.byType(ChannelTilesSkeleton));

    await release(tester, hold);
    expect(find.text('Spotted Pisa'), findsOneWidget);
  });

  testWidgets('Profilo', (tester) async {
    final hold = Completer<void>();
    await pumpApp(tester, profile: HeldProfile(hold));
    await openProfileTab(tester);

    expectSkeleton(find.byType(ListTile));

    await release(tester, hold);
    expect(find.text('@mario_88'), findsOneWidget);
  });

  testWidgets('Home: il carosello dei miei spot', (tester) async {
    final hold = Completer<void>();
    await pumpApp(
      tester,
      spots: HeldSpots(hold, mine: [makeMySpot(1)]),
      settle: false,
    );

    expectSkeleton(find.byType(MySpotsCarouselSkeleton));

    await release(tester, hold);
    expect(find.byType(MySpotCard), findsOneWidget);
  });

  testWidgets('I miei spot: la pagina', (tester) async {
    final hold = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(user: loggedInUser),
          ),
          spotsRepositoryProvider.overrideWithValue(
            HeldSpots(hold, mine: [makeMySpot(1)]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MySpotsPage(),
        ),
      ),
    );
    await advance(tester);

    expectSkeleton(find.byType(SpotCardsSkeleton));

    await release(tester, hold);
    expect(find.text('Spot 1'), findsOneWidget);
  });

  testWidgets('Dettaglio dello spot: lo spot e i commenti', (tester) async {
    final hold = Completer<void>();
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots: HeldSpots(
        hold,
        spots: [makeSpot(1, title: 'Ombrello perso')],
        detail: true,
      ),
    );
    await openChannelsTab(tester);
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ombrello perso'));
    await advance(tester);

    expectSkeleton(find.byType(SpotCardsSkeleton));
    expect(find.byType(CommentsSkeleton), findsOneWidget);

    await release(tester, hold);
  });

  testWidgets('Dettaglio dello spot: solo i commenti', (tester) async {
    final hold = Completer<void>();
    await pumpApp(
      tester,
      channels: FakeChannelsRepository(channels: [channel]),
      spots: FakeSpotsRepository(spots: [makeSpot(1, title: 'Ombrello perso')]),
      comments: HeldComments(hold, comments: [makeComment(1)]),
    );
    await openChannelsTab(tester);
    await tester.tap(find.text('Spotted Pisa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ombrello perso'));
    await advance(tester);

    // Lo spot c'è già; i commenti sono ancora scheletro.
    expect(find.byType(CommentsSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await release(tester, hold);
    expect(find.text('Commento 1'), findsOneWidget);
  });

  testWidgets('Le mie chat', (tester) async {
    final hold = Completer<void>();
    await pumpApp(
      tester,
      chat: HeldChat(hold, chats: [makeChat(1)], list: true),
    );
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await advance(tester);

    expectSkeleton(find.byType(ChatTilesSkeleton));

    await release(tester, hold);
    expect(find.text('@luigi'), findsOneWidget);
  });

  testWidgets('Una chat: intestazione e messaggi', (tester) async {
    final hold = Completer<void>();
    await pumpApp(
      tester,
      chat: HeldChat(hold, chats: [makeChat(1)], detail: true),
    );
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await advance(tester);

    expectSkeleton(find.byType(ChatHeaderSkeleton));
    expect(find.byType(MessagesSkeletonView), findsOneWidget);

    await release(tester, hold);
  });

  testWidgets('Una chat: solo i messaggi', (tester) async {
    final hold = Completer<void>();
    await pumpApp(
      tester,
      chat: HeldChat(
        hold,
        chats: [makeChat(1)],
        messages: {
          'ch1': [makeMessage(1, content: 'Ciao')],
        },
        messageList: true,
      ),
    );
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await advance(tester);

    // L'intestazione c'è già; i messaggi sono ancora scheletro.
    expect(find.text('Ombrello perso'), findsOneWidget);
    expect(find.byType(MessagesSkeletonView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await release(tester, hold);
    expect(find.text('Ciao'), findsOneWidget);
  });

  group('moderazione', () {
    Future<void> openModeration(
      WidgetTester tester, {
      required FakeModerationRepository moderation,
      FakeReportsRepository? reports,
    }) async {
      await pumpApp(
        tester,
        channels: FakeChannelsRepository(channels: [channel]),
        moderation: moderation,
        reports: reports,
      );
      await openChannelsTab(tester);
      await tester.tap(find.text('Spotted Pisa'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.shield_outlined));
      await advance(tester);
    }

    testWidgets('Segnalazioni', (tester) async {
      final hold = Completer<void>();
      await openModeration(
        tester,
        moderation: FakeModerationRepository(ownedChannelIds: {'c1'}),
        reports: HeldReports(hold, reports: [makeReport(1)]),
      );

      expectSkeleton(find.byType(ReportCardsSkeleton));

      await release(tester, hold);
      expect(find.text('Testo spot 1'), findsOneWidget);
    });

    testWidgets('Spot nascosti', (tester) async {
      final hold = Completer<void>();
      final spots = FakeSpotsRepository();
      await openModeration(
        tester,
        moderation: HeldModeration(
          hold,
          ownedChannelIds: {'c1'},
          spotsRepository: spots,
        ),
      );
      await tester.tap(find.text('Spot nascosti'));
      await advance(tester);

      expect(find.byType(SpotCardsSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await release(tester, hold);
      expect(find.text('Nessuno spot nascosto'), findsOneWidget);
    });
  });

  group('pagine successive', () {
    testWidgets('Canali: in fondo all elenco compare un canale in scheletro', (
      tester,
    ) async {
      final slow = SlowPagesChannelsRepository(
        channels: List.generate(25, (i) => makeChannel(i + 1)),
      );
      await pumpApp(tester, channels: slow);
      await openChannelsTab(tester);
      await tester.pumpAndSettle();
      // Da qui la seconda pagina resta in volo.
      slow.gate = Completer<void>();

      await tester.drag(find.byType(ListView).last, const Offset(0, -3000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ChannelTilesSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Quando la pagina arriva, lo scheletro lascia il posto ai canali.
      slow.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ChannelTilesSkeleton), findsNothing);
    });
  });
}
