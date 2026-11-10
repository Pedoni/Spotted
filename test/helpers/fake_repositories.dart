import 'dart:async';

import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/domain/repositories/profile_repository.dart';
import 'package:spotted/features/spots/domain/entities/my_spot.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
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
  String? description,
}) {
  return Channel(
    id: 'c$i',
    name: name ?? 'Canale $i',
    slug: 'canale-$i',
    topicId: topicId,
    place: place,
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
    String? place,
    String? topicId,
  }) async {
    createCalls.add({
      'name': name,
      'slug': slug,
      'description': description,
      'place': place,
      'topicId': topicId,
    });
    if (createError != null) throw createError!;
    if (takenSlugs.contains(slug)) throw const ConflictFailure();
    final channel = Channel(
      id: 'new-${createCalls.length}',
      name: name,
      slug: slug,
      description: description,
      place: place,
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

  @override
  Future<Profile> getMyProfile() async => profile;
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

Spot makeSpot(int i, {String channelId = 'c1', String? title}) {
  return Spot(
    id: 's$i',
    channelId: channelId,
    title: title ?? 'Spot $i',
    content: 'Testo dello spot $i',
    createdAt: DateTime(2026).subtract(Duration(minutes: i)),
  );
}

MySpot makeMySpot(int i, {String channelName = 'Spotted Pisa'}) {
  return MySpot(
    spot: makeSpot(i),
    channelName: channelName,
    channelSlug: 'canale-1',
  );
}

/// Spot in memoria: [spots] sono quelli dei canali, [mine] quelli dell'utente.
/// Se [gate] è impostato, le pagine successive alla prima restano in attesa
/// finché non si completa.
class FakeSpotsRepository implements SpotsRepository {
  FakeSpotsRepository({List<Spot>? spots, List<MySpot>? mine})
    : spots = spots ?? [],
      mine = mine ?? [];

  List<Spot> spots;
  List<MySpot> mine;
  Failure? listError;
  Failure? createError;
  Failure? deleteError;
  Completer<void>? gate;

  final listCalls = <({String channelId, int offset, int limit})>[];
  final mineCalls = <({int offset, int limit})>[];
  final createCalls = <Map<String, String>>[];
  final deleteCalls = <String>[];

  @override
  Future<List<Spot>> getChannelSpots({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    listCalls.add((channelId: channelId, offset: offset, limit: limit));
    if (listError != null) throw listError!;
    if (offset > 0 && gate != null) await gate!.future;
    return spots
        .where((s) => s.channelId == channelId)
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<List<MySpot>> getMySpots({
    required int offset,
    required int limit,
  }) async {
    mineCalls.add((offset: offset, limit: limit));
    if (listError != null) throw listError!;
    if (offset > 0 && gate != null) await gate!.future;
    return mine.skip(offset).take(limit).toList();
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
