import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/data/models/channel_model.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChannelsRemoteDataSource {
  const ChannelsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Channel>> getChannels({
    required int offset,
    required int limit,
    String? query,
    String? topicId,
  }) async {
    var request = _client.from('channels').select(channelColumns);
    if (topicId != null) request = request.eq('topic_id', topicId);
    if (query != null) {
      request = request.ilike('name', '%${_escapeLike(query)}%');
    }
    final rows = await request
        .order('created_at', ascending: false)
        .order('id')
        .range(offset, offset + limit - 1);
    return rows.map(ChannelModel.fromJson).toList();
  }

  Future<Channel> getChannelBySlug(String slug) async {
    final row = await _client
        .from('channels')
        .select(channelColumns)
        .eq('slug', slug)
        .maybeSingle();
    if (row == null) throw const NotFoundFailure();
    return ChannelModel.fromJson(row);
  }

  /// Usa l'RPC `my_channels()`: `owner_id` non è leggibile dalla tabella.
  Future<List<Channel>> getMyChannels() async {
    final rows = await _client.rpc<List<dynamic>>('my_channels');
    return rows
        .cast<Map<String, dynamic>>()
        .map(ChannelModel.fromJson)
        .toList();
  }

  Future<Channel> createChannel({
    required String name,
    required String slug,
    String? description,
    String? place,
    String? topicId,
  }) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const AuthFailure(AuthFailureReason.unknown);
    }
    // `select(channelColumns)` evita di chiedere `owner_id` in `returning`.
    final row = await _client
        .from('channels')
        .insert({
          'owner_id': ownerId,
          'name': name,
          'slug': slug,
          'description': description,
          'place': place,
          'topic_id': topicId,
        })
        .select(channelColumns)
        .single();
    return ChannelModel.fromJson(row);
  }

  /// Rende letterali i caratteri speciali di `like`.
  String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
