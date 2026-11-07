import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/domain/repositories/profile_repository.dart';
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
