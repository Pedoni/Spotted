import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/riverpod/no_retry.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_skeletons.dart';
import 'package:spotted/features/channels/presentation/widgets/channel_tile.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_skeletons.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_tile.dart';
import 'package:spotted/features/chat/presentation/widgets/message_bubble.dart';
import 'package:spotted/features/comments/presentation/widgets/comment_skeletons.dart';
import 'package:spotted/features/comments/presentation/widgets/comment_tile.dart';
import 'package:spotted/features/reports/presentation/widgets/report_card.dart';
import 'package:spotted/features/reports/presentation/widgets/report_skeletons.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_card.dart';
import 'package:spotted/features/spots/presentation/widgets/spot_skeletons.dart';
import 'package:spotted/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

Widget host(Widget child) {
  return ProviderScope(
    retry: noRetry,
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(user: loggedInUser),
      ),
      spotsRepositoryProvider.overrideWithValue(FakeSpotsRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('spot', () {
    testWidgets('SpotCardsSkeleton mostra il numero di card richiesto', (
      tester,
    ) async {
      await tester.pumpWidget(host(const SpotCardsSkeleton()));
      expect(find.byType(SpotCard), findsNWidgets(3));
      expect(find.byType(Skeleton), findsOneWidget);

      await tester.pumpWidget(host(const SpotCardsSkeleton(count: 1)));
      expect(find.byType(SpotCard), findsOneWidget);
    });

    testWidgets('le card hanno titoli e testi di lunghezze diverse', (
      tester,
    ) async {
      await tester.pumpWidget(host(const SpotCardsSkeleton()));

      final titles = tester
          .widgetList<SpotCard>(find.byType(SpotCard))
          .map((card) => card.spot.title.length)
          .toSet();
      expect(titles.length, 3);
    });

    testWidgets('senza canale non mostra il canale, con il canale sì', (
      tester,
    ) async {
      await tester.pumpWidget(host(const SpotCardsSkeleton(count: 1)));
      expect(
        tester.widget<SpotCard>(find.byType(SpotCard)).channelName,
        isNull,
      );

      await tester.pumpWidget(
        host(const SpotCardsSkeleton(count: 1, withChannel: true)),
      );
      expect(
        tester.widget<SpotCard>(find.byType(SpotCard)).channelName,
        isNotNull,
      );
    });

    testWidgets('le card non sono toccabili e non hanno dati veri', (
      tester,
    ) async {
      await tester.pumpWidget(host(const SpotCardsSkeleton()));

      for (final card in tester.widgetList<SpotCard>(find.byType(SpotCard))) {
        expect(card.onTap, isNull);
        expect(card.spot.id, startsWith('skeleton'));
      }
    });

    testWidgets('SpotFormSkeleton mostra due campi e un pulsante', (
      tester,
    ) async {
      await tester.pumpWidget(host(const SpotFormSkeleton()));

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  group('canali', () {
    testWidgets('ChannelTilesSkeleton mostra sei righe per default', (
      tester,
    ) async {
      await tester.pumpWidget(host(const ChannelTilesSkeleton()));

      expect(find.byType(ChannelTile), findsNWidgets(6));
      expect(find.byType(Skeleton), findsOneWidget);
    });

    testWidgets('si può chiedere un numero diverso di righe', (tester) async {
      await tester.pumpWidget(host(const ChannelTilesSkeleton(count: 2)));

      expect(find.byType(ChannelTile), findsNWidgets(2));
    });

    testWidgets(
      'ChannelHeaderSkeleton ha nome, chip, descrizione e iscrizione',
      (
        tester,
      ) async {
        await tester.pumpWidget(host(const ChannelHeaderSkeleton()));

        expect(find.byType(Chip), findsNWidgets(2));
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(Skeleton), findsOneWidget);
      },
    );
  });

  group('commenti', () {
    testWidgets('CommentsSkeleton mostra tre commenti per default', (
      tester,
    ) async {
      await tester.pumpWidget(host(const CommentsSkeleton()));

      expect(find.byType(CommentTile), findsNWidgets(3));
    });

    testWidgets('i commenti finti non sono dell utente', (tester) async {
      await tester.pumpWidget(host(const CommentsSkeleton()));

      for (final tile in tester.widgetList<CommentTile>(
        find.byType(CommentTile),
      )) {
        expect(tile.comment.isMine, isFalse);
        expect(tile.comment.isSpotAuthor, isFalse);
      }
    });
  });

  group('chat', () {
    testWidgets('ChatTilesSkeleton mostra le righe delle chat', (tester) async {
      await tester.pumpWidget(host(const ChatTilesSkeleton(count: 4)));

      expect(find.byType(ChatTile), findsNWidgets(4));
    });

    testWidgets('MessagesSkeleton alterna messaggi miei e dell altro', (
      tester,
    ) async {
      await tester.pumpWidget(host(const MessagesSkeleton(count: 4)));

      final mine = tester
          .widgetList<MessageBubble>(find.byType(MessageBubble))
          .map((bubble) => bubble.message.isMine)
          .toList();
      expect(mine, [false, true, false, true]);
    });

    testWidgets(
      'MessagesSkeletonView non scorre e ancora i messaggi in basso',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          host(const SizedBox(height: 600, child: MessagesSkeletonView())),
        );

        final scroll = tester.widget<SingleChildScrollView>(
          find.descendant(
            of: find.byType(MessagesSkeletonView),
            matching: find.byType(SingleChildScrollView),
          ),
        );
        expect(scroll.reverse, isTrue);
        expect(scroll.physics, isA<NeverScrollableScrollPhysics>());
      },
    );

    testWidgets('ChatHeaderSkeleton ha lo spot e il canale', (tester) async {
      await tester.pumpWidget(host(const ChatHeaderSkeleton()));

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byType(Skeleton), findsOneWidget);
    });
  });

  group('segnalazioni', () {
    testWidgets('ReportCardsSkeleton mostra le card delle segnalazioni', (
      tester,
    ) async {
      await tester.pumpWidget(host(const ReportCardsSkeleton(count: 2)));

      expect(find.byType(ReportCard), findsNWidgets(2));
    });
  });
}
