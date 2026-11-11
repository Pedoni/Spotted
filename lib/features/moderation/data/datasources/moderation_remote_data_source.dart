import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/moderation/data/models/spot_author_dto.dart';
import 'package:spotted/features/moderation/domain/entities/moderation_status.dart';
import 'package:spotted/features/moderation/domain/entities/spot_author.dart';
import 'package:spotted/features/spots/data/models/spot_dto.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tutto passa da RPC riservate al proprietario del canale: se chi chiama non
/// lo è, il database risponde `42501`.
class ModerationRemoteDataSource {
  const ModerationRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<bool> isChannelOwner(String channelId) async {
    final owner = await _client.rpc<bool>(
      'is_channel_owner',
      params: {'p_channel_id': channelId},
    );
    return owner;
  }

  /// L'RPC non restituisce righe se lo spot non esiste.
  Future<SpotAuthor> getSpotAuthor(String spotId) async {
    final rows = await _client.rpc<List<dynamic>>(
      'channel_spot_author',
      params: {'p_spot_id': spotId},
    );
    if (rows.isEmpty) throw const NotFoundFailure();
    return SpotAuthorDto.fromJson(
      rows.cast<Map<String, dynamic>>().single,
    ).toEntity();
  }

  /// L'RPC restituisce `false` se lo spot non esiste, è già rimosso o ha già
  /// quello stato.
  Future<void> setSpotStatus(String spotId, ModerationStatus status) async {
    final changed = await _client.rpc<bool>(
      'set_spot_status',
      params: {'p_spot_id': spotId, 'p_status': status.name},
    );
    if (!changed) throw const NotFoundFailure();
  }

  /// L'RPC restituisce `false` se il commento non esiste o ha già quello
  /// stato.
  Future<void> setCommentHidden(
    String commentId, {
    required bool hidden,
  }) async {
    final changed = await _client.rpc<bool>(
      'set_comment_status',
      params: {
        'p_comment_id': commentId,
        'p_status': hidden ? 'hidden' : 'published',
      },
    );
    if (!changed) throw const NotFoundFailure();
  }

  Future<List<Spot>> getHiddenSpots({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'channel_moderation_spots_page',
      params: {
        'p_channel_id': channelId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    // Questi spot sono nascosti per definizione: l'RPC non restituisce lo
    // stato.
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => SpotDto.fromJson({...row, 'status': 'hidden'}).toEntity())
        .toList();
  }
}
