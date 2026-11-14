import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/data/models/channel_dto.dart';
import 'package:spotted/features/channels/data/models/create_channel_dto.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChannelsRemoteDataSource {
  /// [currentUserId] permette di fornire l'id utente nei test; di default è
  /// quello della sessione Supabase.
  ChannelsRemoteDataSource(
    this._client, {
    String? Function()? currentUserId,
  }) : _currentUserId = currentUserId ?? (() => _client.auth.currentUser?.id);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  Future<List<Channel>> getChannels({
    required int offset,
    required int limit,
    String? query,
    String? topicId,
    String? regionName,
    String? provinceCode,
    String? municipalityId,
  }) async {
    var request = _client.from('channels').select(channelColumns);
    if (topicId != null) request = request.eq('topic_id', topicId);
    if (regionName != null) request = request.eq('region_name', regionName);
    if (provinceCode != null) {
      request = request.eq('province_code', provinceCode);
    }
    if (municipalityId != null) {
      request = request.eq('municipality_id', municipalityId);
    }
    if (query != null) {
      request = request.ilike('name', '%${_escapeLike(query)}%');
    }
    final rows = await request
        .order('created_at', ascending: false)
        .order('id')
        .range(offset, offset + limit - 1);
    return rows.map((row) => ChannelDto.fromJson(row).toEntity()).toList();
  }

  Future<Channel> getChannelBySlug(String slug) async {
    final row = await _client
        .from('channels')
        .select(channelColumns)
        .eq('slug', slug)
        .maybeSingle();
    if (row == null) throw const NotFoundFailure();
    return ChannelDto.fromJson(row).toEntity();
  }

  /// Usa l'RPC `my_channels()`: `owner_id` non è leggibile dalla tabella.
  Future<List<Channel>> getMyChannels() async {
    final rows = await _client.rpc<List<dynamic>>('my_channels');
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => ChannelDto.fromJson(row).toEntity())
        .toList();
  }

  Future<Channel> createChannel({
    required String name,
    required String slug,
    String? description,
    String? municipalityId,
    String? topicId,
  }) async {
    final ownerId = _currentUserId();
    if (ownerId == null) {
      throw const AuthFailure(AuthFailureReason.unknown);
    }
    // `select(channelColumns)` evita di chiedere `owner_id` in `returning`.
    final dto = CreateChannelDto(
      ownerId: ownerId,
      name: name,
      slug: slug,
      description: description,
      municipalityId: municipalityId,
      topicId: topicId,
    );
    final row = await _client
        .from('channels')
        .insert(dto.toJson())
        .select(channelColumns)
        .single();
    return ChannelDto.fromJson(row).toEntity();
  }

  /// Rende letterali i caratteri speciali di `like`.
  String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
