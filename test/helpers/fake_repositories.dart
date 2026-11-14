import 'dart:async';

import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';
import 'package:spotted/features/chat/domain/entities/chat_message.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';
import 'package:spotted/features/comments/domain/entities/comment.dart';
import 'package:spotted/features/comments/domain/entities/comment_status.dart';
import 'package:spotted/features/comments/domain/repositories/comments_repository.dart';
import 'package:spotted/features/moderation/domain/entities/moderation_status.dart';
import 'package:spotted/features/moderation/domain/entities/spot_author.dart';
import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:spotted/features/municipalities/domain/entities/municipality.dart';
import 'package:spotted/features/municipalities/domain/entities/province.dart';
import 'package:spotted/features/municipalities/domain/repositories/municipalities_repository.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/domain/repositories/profile_repository.dart';
import 'package:spotted/features/reports/domain/entities/channel_report.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';
import 'package:spotted/features/reports/domain/entities/report_resolution.dart';
import 'package:spotted/features/reports/domain/repositories/reports_repository.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';
import 'package:spotted/features/spots/domain/entities/spot_status.dart';
import 'package:spotted/features/spots/domain/entities/spot_with_channel.dart';
import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';
import 'package:spotted/features/subscriptions/domain/entities/subscription_info.dart';
import 'package:spotted/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:spotted/features/topics/domain/entities/topic.dart';
import 'package:spotted/features/topics/domain/repositories/topics_repository.dart';

Channel makeChannel(
  int i, {
  String? name,
  String? topicId,
  String? place,
  String? municipalityId,
  String? description,
}) {
  return Channel(
    id: 'c$i',
    name: name ?? 'Canale $i',
    slug: 'canale-$i',
    topicId: topicId,
    place: place,
    municipalityId: municipalityId,
    description: description,
    createdAt: DateTime(2026).subtract(Duration(minutes: i)),
  );
}

class FakeChannelsRepository implements ChannelsRepository {
  FakeChannelsRepository({
    List<Channel>? channels,
    List<Channel>? mine,
  }) : channels = channels ?? [],
       mine = mine ?? [];

  List<Channel> channels;
  List<Channel> mine;
  Set<String> takenSlugs = {};

  /// Il testo da mostrare di ogni comune (come lo calcola il database).
  Map<String, String> municipalityPlaces = {'050026': 'Pisa (PI)'};
  Failure? listError;
  Failure? createError;

  final listCalls =
      <({int offset, int limit, String? query, String? topicId})>[];
  final createCalls = <Map<String, String?>>[];

  @override
  Future<List<Channel>> getChannels({
    required int offset,
    required int limit,
    String? query,
    String? topicId,
  }) async {
    listCalls.add((
      offset: offset,
      limit: limit,
      query: query,
      topicId: topicId,
    ));
    if (listError != null) throw listError!;
    final filtered = channels.where((c) {
      final matchesQuery =
          query == null || c.name.toLowerCase().contains(query.toLowerCase());
      final matchesTopic = topicId == null || c.topicId == topicId;
      return matchesQuery && matchesTopic;
    }).toList();
    return filtered.skip(offset).take(limit).toList();
  }

  @override
  Future<Channel> getChannelBySlug(String slug) async {
    return [...channels, ...mine].firstWhere(
      (c) => c.slug == slug,
      orElse: () => throw const NotFoundFailure(),
    );
  }

  @override
  Future<List<Channel>> getMyChannels() async => mine;

  @override
  Future<Channel> createChannel({
    required String name,
    required String slug,
    String? description,
    String? municipalityId,
    String? topicId,
  }) async {
    createCalls.add({
      'name': name,
      'slug': slug,
      'description': description,
      'municipalityId': municipalityId,
      'topicId': topicId,
    });
    if (createError != null) throw createError!;
    if (takenSlugs.contains(slug)) throw const ConflictFailure();
    final channel = Channel(
      id: 'new-${createCalls.length}',
      name: name,
      slug: slug,
      description: description,
      // Come il trigger del database: il luogo da mostrare viene dal comune.
      place: municipalityId == null ? null : municipalityPlaces[municipalityId],
      municipalityId: municipalityId,
      topicId: topicId,
      createdAt: DateTime(2026),
    );
    channels = [channel, ...channels];
    mine = [channel, ...mine];
    return channel;
  }
}

/// Repository in cui le pagine successive alla prima restano in attesa finché
/// non si completa [gate]: simula una richiesta lenta ancora in volo.
class SlowPagesChannelsRepository extends FakeChannelsRepository {
  SlowPagesChannelsRepository({super.channels});

  Completer<void>? gate;

  @override
  Future<List<Channel>> getChannels({
    required int offset,
    required int limit,
    String? query,
    String? topicId,
  }) async {
    if (offset > 0 && gate != null) await gate!.future;
    return super.getChannels(
      offset: offset,
      limit: limit,
      query: query,
      topicId: topicId,
    );
  }
}

class FakeTopicsRepository implements TopicsRepository {
  FakeTopicsRepository({List<Topic>? topics})
    : topics =
          topics ??
          const [
            Topic(id: 't-uni', name: 'Università'),
            Topic(id: 't-sport', name: 'Sport'),
          ];

  List<Topic> topics;

  @override
  Future<List<Topic>> getTopics() async => topics;
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    this.profile = const Profile(
      id: '1',
      username: 'mario_88',
      firstName: 'Mario',
      lastName: 'Rossi',
    ),
  });

  Profile profile;
  Failure? error;

  @override
  Future<Profile> getMyProfile() async {
    if (error != null) throw error!;
    return profile;
  }
}

/// Iscrizioni in memoria. [counts] è il numero di iscritti per canale (compreso
/// l'utente, se iscritto). Se [gate] è impostato, subscribe/unsubscribe restano
/// in attesa finché non si completa.
class FakeSubscriptionsRepository implements SubscriptionsRepository {
  FakeSubscriptionsRepository({
    List<Channel>? channels,
    Set<String>? subscribedIds,
    Map<String, int>? counts,
  }) : channels = channels ?? [],
       subscribedIds = subscribedIds ?? {},
       counts = counts ?? {};

  List<Channel> channels;
  Set<String> subscribedIds;
  Map<String, int> counts;
  Failure? toggleError;
  Failure? listError;
  Completer<void>? gate;

  final calls = <String>[];

  @override
  Future<SubscriptionInfo> getInfo(String channelId) async {
    return SubscriptionInfo(
      subscriberCount: counts[channelId] ?? 0,
      isSubscribed: subscribedIds.contains(channelId),
    );
  }

  @override
  Future<void> subscribe(String channelId) async {
    calls.add('subscribe:$channelId');
    if (gate != null) await gate!.future;
    if (toggleError != null) throw toggleError!;
    if (subscribedIds.add(channelId)) {
      counts[channelId] = (counts[channelId] ?? 0) + 1;
    }
  }

  @override
  Future<void> unsubscribe(String channelId) async {
    calls.add('unsubscribe:$channelId');
    if (gate != null) await gate!.future;
    if (toggleError != null) throw toggleError!;
    if (subscribedIds.remove(channelId)) {
      counts[channelId] = (counts[channelId] ?? 1) - 1;
    }
  }

  @override
  Future<List<Channel>> getMySubscribedChannels() async {
    if (listError != null) throw listError!;
    return channels.where((c) => subscribedIds.contains(c.id)).toList();
  }
}

Spot makeSpot(
  int i, {
  String channelId = 'c1',
  String? title,
  String? content,
  SpotStats stats = const SpotStats(),
  SpotStatus status = SpotStatus.published,
}) {
  return Spot(
    id: 's$i',
    channelId: channelId,
    title: title ?? 'Spot $i',
    content: content ?? 'Testo dello spot $i',
    createdAt: DateTime(2026).subtract(Duration(minutes: i)),
    stats: stats,
    status: status,
  );
}

SpotWithChannel makeMySpot(int i, {String channelName = 'Spotted Pisa'}) {
  return SpotWithChannel(
    spot: makeSpot(i),
    channelName: channelName,
    channelSlug: 'canale-1',
  );
}

/// Spot in memoria: [spots] sono quelli dei canali, [mine] quelli dell'utente.
/// Se [gate] è impostato, le pagine successive alla prima restano in attesa
/// finché non si completa.
class FakeSpotsRepository implements SpotsRepository {
  FakeSpotsRepository({
    List<Spot>? spots,
    List<SpotWithChannel>? mine,
    List<SpotWithChannel>? followed,
  }) : spots = spots ?? [],
       mine = mine ?? [],
       followed = followed ?? [];

  List<Spot> spots;
  List<SpotWithChannel> mine;
  Failure? listError;
  Failure? createError;
  Failure? deleteError;
  Failure? likeError;
  Completer<void>? gate;

  final likeCalls = <({String spotId, bool liked})>[];
  final listCalls = <({String channelId, int offset, int limit})>[];

  /// Il testo cercato in ogni chiamata di `getChannelSpots` (`null` se non si
  /// cercava), nello stesso ordine di [listCalls].
  final queries = <String?>[];
  final mineCalls = <({int offset, int limit})>[];
  final createCalls = <Map<String, String>>[];
  final deleteCalls = <String>[];

  static String _plain(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[àá]'), 'a')
      .replaceAll(RegExp('[èé]'), 'e')
      .replaceAll(RegExp('[ìí]'), 'i')
      .replaceAll(RegExp('[òó]'), 'o')
      .replaceAll(RegExp('[ùú]'), 'u');

  @override
  Future<List<Spot>> getChannelSpots({
    required String channelId,
    required int offset,
    required int limit,
    String? query,
  }) async {
    listCalls.add((channelId: channelId, offset: offset, limit: limit));
    queries.add(query);
    if (listError != null) throw listError!;
    if (offset > 0 && gate != null) await gate!.future;
    final text = query == null ? null : _plain(query.trim());
    return spots
        .where(
          (s) => s.channelId == channelId && s.status == SpotStatus.published,
        )
        // Come l'RPC: titolo o testo contengono il testo, senza maiuscole e
        // accenti.
        .where(
          (s) =>
              text == null ||
              text.isEmpty ||
              _plain(s.title).contains(text) ||
              _plain(s.content).contains(text),
        )
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<Spot> getSpot(String spotId) async {
    return [
      ...spots,
      ...mine.map((m) => m.spot),
    ].firstWhere(
      (s) => s.id == spotId,
      orElse: () => throw const NotFoundFailure(),
    );
  }

  @override
  Future<void> setSpotLiked(String spotId, {required bool liked}) async {
    likeCalls.add((spotId: spotId, liked: liked));
    if (likeError != null) throw likeError!;
  }

  @override
  Future<List<SpotWithChannel>> getMySpots({
    required int offset,
    required int limit,
  }) async {
    mineCalls.add((offset: offset, limit: limit));
    if (listError != null) throw listError!;
    if (offset > 0 && gate != null) await gate!.future;
    return mine.skip(offset).take(limit).toList();
  }

  final List<SpotWithChannel> followed;

  /// Errore solo per gli spot dei canali seguiti (la Home).
  Failure? followedError;
  final followedCalls = <({int offset, int limit})>[];

  @override
  Future<List<SpotWithChannel>> getFollowedSpots({
    required int offset,
    required int limit,
  }) async {
    followedCalls.add((offset: offset, limit: limit));
    if (followedError != null) throw followedError!;
    return followed.skip(offset).take(limit).toList();
  }

  @override
  Future<Spot> createSpot({
    required String channelId,
    required String title,
    required String content,
  }) async {
    createCalls.add({
      'channelId': channelId,
      'title': title,
      'content': content,
    });
    if (createError != null) throw createError!;
    final spot = Spot(
      id: 'new-${createCalls.length}',
      channelId: channelId,
      title: title,
      content: content,
      createdAt: DateTime(2026),
    );
    spots = [spot, ...spots];
    return spot;
  }

  @override
  Future<void> deleteSpot(String spotId) async {
    deleteCalls.add(spotId);
    if (deleteError != null) throw deleteError!;
    final before = mine.length + spots.length;
    mine = mine.where((m) => m.spot.id != spotId).toList();
    spots = spots.where((s) => s.id != spotId).toList();
    if (mine.length + spots.length == before) throw const NotFoundFailure();
  }
}

Comment makeComment(
  int i, {
  String spotId = 's1',
  String? content,
  String? authorUsername = 'luigi',
  bool isSpotAuthor = false,
  bool isMine = false,
  int likeCount = 0,
  bool likedByMe = false,
  CommentStatus status = CommentStatus.published,
}) {
  return Comment(
    id: 'k$i',
    spotId: spotId,
    content: content ?? 'Commento $i',
    createdAt: DateTime(2026).subtract(Duration(minutes: i)),
    authorUsername: isSpotAuthor ? null : authorUsername,
    isSpotAuthor: isSpotAuthor,
    isMine: isMine,
    likeCount: likeCount,
    likedByMe: likedByMe,
    status: status,
  );
}

/// Commenti in memoria. Se [gate] è impostato, le pagine successive alla prima
/// restano in attesa finché non si completa.
class FakeCommentsRepository implements CommentsRepository {
  FakeCommentsRepository({List<Comment>? comments}) : comments = comments ?? [];

  List<Comment> comments;
  Failure? listError;
  Failure? addError;
  Failure? deleteError;
  Failure? likeError;
  Completer<void>? gate;

  final listCalls = <({String spotId, int offset, int limit})>[];
  final addCalls = <({String spotId, String content})>[];
  final deleteCalls = <String>[];
  final likeCalls = <({String commentId, bool liked})>[];

  @override
  Future<List<Comment>> getSpotComments({
    required String spotId,
    required int offset,
    required int limit,
  }) async {
    listCalls.add((spotId: spotId, offset: offset, limit: limit));
    if (listError != null) throw listError!;
    if (offset > 0 && gate != null) await gate!.future;
    return comments
        .where((c) => c.spotId == spotId)
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<Comment> addComment({
    required String spotId,
    required String content,
  }) async {
    addCalls.add((spotId: spotId, content: content));
    if (addError != null) throw addError!;
    final comment = Comment(
      id: 'new-${addCalls.length}',
      spotId: spotId,
      content: content,
      createdAt: DateTime(2026),
      authorUsername: 'mario_88',
      isSpotAuthor: false,
      isMine: true,
    );
    comments = [comment, ...comments];
    return comment;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    deleteCalls.add(commentId);
    if (deleteError != null) throw deleteError!;
    final before = comments.length;
    comments = comments.where((c) => c.id != commentId).toList();
    if (comments.length == before) throw const NotFoundFailure();
  }

  @override
  Future<void> setCommentLiked(String commentId, {required bool liked}) async {
    likeCalls.add((commentId: commentId, liked: liked));
    if (likeError != null) throw likeError!;
  }
}

/// Strumenti del proprietario in memoria. [ownedChannelIds] sono i canali di
/// cui l'utente è proprietario. Se sono passati [spotsRepository] e
/// [commentsRepository], le modifiche di stato si riflettono lì.
class FakeModerationRepository implements ModerationRepository {
  FakeModerationRepository({
    this.ownedChannelIds = const {},
    this.spotsRepository,
    this.commentsRepository,
  });

  Set<String> ownedChannelIds;
  final FakeSpotsRepository? spotsRepository;
  final FakeCommentsRepository? commentsRepository;

  SpotAuthor author = const SpotAuthor(id: 'u9', username: 'giulia_77');
  Failure? ownerError;
  Failure? authorError;
  Failure? statusError;
  Failure? commentError;
  Failure? listError;

  final statusCalls = <({String spotId, ModerationStatus status})>[];
  final commentCalls = <({String commentId, bool hidden})>[];
  final authorCalls = <String>[];
  final hiddenCalls = <({String channelId, int offset, int limit})>[];

  @override
  Future<bool> isChannelOwner(String channelId) async {
    if (ownerError != null) throw ownerError!;
    return ownedChannelIds.contains(channelId);
  }

  @override
  Future<SpotAuthor> getSpotAuthor(String spotId) async {
    authorCalls.add(spotId);
    if (authorError != null) throw authorError!;
    return author;
  }

  @override
  Future<void> setSpotStatus(String spotId, ModerationStatus status) async {
    statusCalls.add((spotId: spotId, status: status));
    if (statusError != null) throw statusError!;
    final repository = spotsRepository;
    if (repository == null) return;
    if (status == ModerationStatus.removed) {
      repository.spots = repository.spots.where((s) => s.id != spotId).toList();
      return;
    }
    repository.spots = [
      for (final s in repository.spots)
        if (s.id == spotId)
          Spot(
            id: s.id,
            channelId: s.channelId,
            title: s.title,
            content: s.content,
            createdAt: s.createdAt,
            stats: s.stats,
            status: status == ModerationStatus.hidden
                ? SpotStatus.hidden
                : SpotStatus.published,
          )
        else
          s,
    ];
  }

  @override
  Future<void> setCommentHidden(
    String commentId, {
    required bool hidden,
  }) async {
    commentCalls.add((commentId: commentId, hidden: hidden));
    if (commentError != null) throw commentError!;
    final repository = commentsRepository;
    if (repository == null) return;
    repository.comments = [
      for (final c in repository.comments)
        if (c.id == commentId)
          c.withStatus(hidden ? CommentStatus.hidden : CommentStatus.published)
        else
          c,
    ];
  }

  @override
  Future<List<Spot>> getHiddenSpots({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    hiddenCalls.add((channelId: channelId, offset: offset, limit: limit));
    if (listError != null) throw listError!;
    return (spotsRepository?.spots ?? const <Spot>[])
        .where(
          (s) => s.channelId == channelId && s.status == SpotStatus.hidden,
        )
        .skip(offset)
        .take(limit)
        .toList();
  }
}

ChannelReport makeReport(
  int i, {
  ReportKind kind = ReportKind.spot,
  ReportReason reason = ReportReason.spam,
  String? details,
}) {
  return ChannelReport(
    id: 'r$i',
    kind: kind,
    spotId: 's1',
    spotTitle: 'Spot segnalato $i',
    content: kind == ReportKind.spot ? 'Testo spot $i' : 'Testo commento $i',
    reason: reason,
    details: details,
    createdAt: DateTime(2026).subtract(Duration(minutes: i)),
  );
}

/// Segnalazioni in memoria: [reports] sono quelle aperte del canale.
class FakeReportsRepository implements ReportsRepository {
  FakeReportsRepository({List<ChannelReport>? reports})
    : reports = reports ?? [];

  List<ChannelReport> reports;
  Failure? reportError;
  Failure? listError;
  Failure? resolveError;

  final spotCalls = <({String spotId, ReportReason reason, String? details})>[];
  final commentCalls =
      <({String commentId, ReportReason reason, String? details})>[];
  final listCalls = <({String channelId, int offset, int limit})>[];
  final resolveCalls = <({String reportId, ReportResolution resolution})>[];

  @override
  Future<void> reportSpot({
    required String spotId,
    required ReportReason reason,
    String? details,
  }) async {
    spotCalls.add((spotId: spotId, reason: reason, details: details));
    if (reportError != null) throw reportError!;
  }

  @override
  Future<void> reportComment({
    required String commentId,
    required ReportReason reason,
    String? details,
  }) async {
    commentCalls.add((commentId: commentId, reason: reason, details: details));
    if (reportError != null) throw reportError!;
  }

  @override
  Future<List<ChannelReport>> getChannelReports({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    listCalls.add((channelId: channelId, offset: offset, limit: limit));
    if (listError != null) throw listError!;
    return reports.skip(offset).take(limit).toList();
  }

  @override
  Future<void> resolveReport(
    String reportId,
    ReportResolution resolution,
  ) async {
    resolveCalls.add((reportId: reportId, resolution: resolution));
    if (resolveError != null) throw resolveError!;
    reports = reports.where((r) => r.id != reportId).toList();
  }
}

ChatSummary makeChat(
  int i, {
  bool iAmAuthor = true,
  String? otherUsername = 'luigi',
  bool identityRevealed = false,
  String? lastMessage,
  bool? lastMessageIsMine,
}) {
  return ChatSummary(
    id: 'ch$i',
    spotId: 's1',
    spotTitle: 'Ombrello perso',
    channelName: 'Spotted Pisa',
    channelSlug: 'canale-1',
    iAmAuthor: iAmAuthor,
    otherUsername: otherUsername,
    identityRevealed: identityRevealed,
    createdAt: DateTime(2026).subtract(Duration(minutes: i)),
    lastMessage: lastMessage,
    lastMessageAt: lastMessage == null
        ? null
        : DateTime(2026).subtract(Duration(minutes: i)),
    lastMessageIsMine: lastMessageIsMine,
  );
}

ChatMessage makeMessage(int i, {String? content, bool isMine = false}) {
  return ChatMessage(
    id: 'm$i',
    content: content ?? 'Messaggio $i',
    createdAt: DateTime(2026).subtract(Duration(minutes: i)),
    isMine: isMine,
  );
}

/// Chat in memoria. [messages] sono i messaggi di ogni chat, dal più recente.
/// Se [gate] è impostato, le pagine successive alla prima restano in attesa
/// finché non si completa.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({
    List<ChatSummary>? chats,
    Map<String, List<ChatMessage>>? messages,
    this.spotAuthor = false,
  }) : chats = chats ?? [],
       messages = messages ?? {};

  List<ChatSummary> chats;
  Map<String, List<ChatMessage>> messages;

  /// L'utente loggato è l'autore dello spot.
  bool spotAuthor;

  Failure? authorError;
  Failure? startError;
  Failure? revealError;
  Failure? listError;
  Failure? detailError;
  Failure? messagesError;
  Failure? sendError;
  Completer<void>? gate;

  final startCalls = <String>[];
  final revealCalls = <String>[];
  final listCalls = <({int offset, int limit})>[];
  final messageCalls = <({String chatId, int offset, int limit})>[];
  final sendCalls = <({String chatId, String content})>[];

  @override
  Future<bool> isSpotAuthor(String spotId) async {
    if (authorError != null) throw authorError!;
    return spotAuthor;
  }

  @override
  Future<String> startChat(String commentId) async {
    startCalls.add(commentId);
    if (startError != null) throw startError!;
    return chats.isEmpty ? 'ch-new' : chats.first.id;
  }

  @override
  Future<void> revealIdentity(String chatId) async {
    revealCalls.add(chatId);
    if (revealError != null) throw revealError!;
    chats = [
      for (final c in chats)
        if (c.id == chatId) c.withIdentityRevealed() else c,
    ];
  }

  @override
  Future<List<ChatSummary>> getChats({
    required int offset,
    required int limit,
  }) async {
    listCalls.add((offset: offset, limit: limit));
    if (listError != null) throw listError!;
    if (offset > 0 && gate != null) await gate!.future;
    return chats.skip(offset).take(limit).toList();
  }

  @override
  Future<ChatSummary> getChat(String chatId) async {
    if (detailError != null) throw detailError!;
    return chats.firstWhere(
      (c) => c.id == chatId,
      orElse: () => throw const NotFoundFailure(),
    );
  }

  @override
  Future<List<ChatMessage>> getMessages({
    required String chatId,
    required int offset,
    required int limit,
  }) async {
    messageCalls.add((chatId: chatId, offset: offset, limit: limit));
    if (messagesError != null) throw messagesError!;
    if (offset > 0 && gate != null) await gate!.future;
    return (messages[chatId] ?? const <ChatMessage>[])
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String content,
  }) async {
    sendCalls.add((chatId: chatId, content: content));
    if (sendError != null) throw sendError!;
    final message = ChatMessage(
      id: 'new-${sendCalls.length}',
      content: content,
      createdAt: DateTime(2026),
      isMine: true,
    );
    messages[chatId] = [message, ...?messages[chatId]];
    return message;
  }
}

/// Un comune di prova: di default Pisa.
Municipality makeMunicipality({
  String code = '050026',
  String name = 'Pisa',
  String provinceCode = 'PI',
  String provinceName = 'Pisa',
  String regionName = 'Toscana',
}) {
  return Municipality(
    istatCode: code,
    name: name,
    provinceCode: provinceCode,
    provinceName: provinceName,
    regionName: regionName,
  );
}

/// L'elenco dei comuni in memoria. La ricerca non distingue maiuscole e
/// accenti e mette prima i nomi che iniziano così, come l'RPC.
class FakeMunicipalitiesRepository implements MunicipalitiesRepository {
  FakeMunicipalitiesRepository({List<Municipality>? municipalities})
    : municipalities =
          municipalities ??
          [
            makeMunicipality(),
            makeMunicipality(
              code: '050027',
              name: 'Pistoia',
              provinceCode: 'PT',
              provinceName: 'Pistoia',
            ),
            makeMunicipality(
              code: '033032',
              name: 'Piacenza',
              provinceCode: 'PC',
              provinceName: 'Piacenza',
              regionName: 'Emilia-Romagna',
            ),
            makeMunicipality(
              code: '008888',
              name: 'Forlì',
              provinceCode: 'FC',
              provinceName: 'Forlì-Cesena',
              regionName: 'Emilia-Romagna',
            ),
          ];

  List<Municipality> municipalities;
  Failure? searchError;
  Failure? listError;

  final searchCalls = <({String query, int limit})>[];

  static String _plain(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[àá]'), 'a')
      .replaceAll(RegExp('[èé]'), 'e')
      .replaceAll(RegExp('[ìí]'), 'i')
      .replaceAll(RegExp('[òó]'), 'o')
      .replaceAll(RegExp('[ùú]'), 'u');

  @override
  Future<List<Municipality>> search(String query, {required int limit}) async {
    searchCalls.add((query: query, limit: limit));
    if (searchError != null) throw searchError!;
    final q = _plain(query.trim());
    final found =
        municipalities.where((m) => _plain(m.name).contains(q)).toList()
          ..sort((a, b) {
            final aStarts = _plain(a.name).startsWith(q) ? 0 : 1;
            final bStarts = _plain(b.name).startsWith(q) ? 0 : 1;
            return aStarts != bStarts
                ? aStarts.compareTo(bStarts)
                : a.name.compareTo(b.name);
          });
    return found.take(limit).toList();
  }

  @override
  Future<List<String>> getRegions() async {
    if (listError != null) throw listError!;
    return ({for (final m in municipalities) m.regionName}.toList()..sort());
  }

  @override
  Future<List<Province>> getProvinces({String? region}) async {
    if (listError != null) throw listError!;
    final found = <String, Province>{
      for (final m in municipalities)
        if (region == null || m.regionName == region)
          m.provinceCode: Province(
            code: m.provinceCode,
            name: m.provinceName,
            regionName: m.regionName,
          ),
    };
    return found.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}
