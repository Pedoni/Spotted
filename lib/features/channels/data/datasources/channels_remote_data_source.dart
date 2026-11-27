import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/data/models/channel_dto.dart';
import 'package:spotted/features/channels/data/models/channel_map_pin_dto.dart';
import 'package:spotted/features/channels/data/models/create_channel_dto.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/entities/channel_map_pin.dart';
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

  /// Usa l'RPC `channels_map`: un pin per comune, con i canali già contati.
  /// Manda solo i filtri attivi, come `getChannels`.
  Future<List<ChannelMapPin>> getChannelsMap({
    String? query,
    String? topicId,
    String? regionName,
    String? provinceCode,
    String? municipalityId,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'channels_map',
      params: {
        'p_query': ?query,
        'p_topic_id': ?topicId,
        'p_region_name': ?regionName,
        'p_province_code': ?provinceCode,
        'p_municipality_id': ?municipalityId,
      },
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => ChannelMapPinDto.fromJson(row).toEntity())
        .toList();
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

  /// Usa l'RPC `update_channel`: la tabella non ha grant di `update`. Lo slug
  /// non cambia. Per chi non è il proprietario risponde `42501`.
  Future<Channel> updateChannel({
    required String channelId,
    required String name,
    String? description,
    String? topicId,
    String? municipalityId,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'update_channel',
      params: {
        'p_channel_id': channelId,
        'p_name': name,
        'p_description': description,
        'p_topic_id': topicId,
        'p_municipality_id': municipalityId,
      },
    );
    if (rows.isEmpty) throw const NotFoundFailure();
    return ChannelDto.fromJson(rows.first as Map<String, dynamic>).toEntity();
  }

  /// Usa l'RPC `delete_channel`: elimina anche spot, commenti e chat del
  /// canale. Per chi non è il proprietario risponde `42501`.
  Future<void> deleteChannel(String channelId) async {
    await _client.rpc<dynamic>(
      'delete_channel',
      params: {'p_channel_id': channelId},
    );
  }

  /// Rende letterali i caratteri speciali di `like`.
  String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
