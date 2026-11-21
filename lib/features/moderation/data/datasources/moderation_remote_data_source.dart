import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/moderation/data/models/blocked_user_dto.dart';
import 'package:spotted/features/moderation/data/models/spot_author_dto.dart';
import 'package:spotted/features/moderation/domain/entities/blocked_user.dart';
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

  /// Gli spot in attesa non hanno né "mi piace" né commenti né tag: l'RPC non
  /// restituisce nemmeno lo stato.
  Future<List<Spot>> getPendingSpots({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'channel_pending_spots_page',
      params: {
        'p_channel_id': channelId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map(
          (row) => SpotDto.fromJson({...row, 'status': 'pending'}).toEntity(),
        )
        .toList();
  }

  Future<int> getPendingSpotsCount(String channelId) async {
    final count = await _client.rpc<int>(
      'channel_pending_spots_count',
      params: {'p_channel_id': channelId},
    );
    return count;
  }

  /// L'RPC restituisce `false` se lo spot non esiste o non è in attesa, e
  /// risponde `23514` (`ValidationFailure`) se i tag non valgono.
  Future<void> approveSpot(String spotId, List<String> tags) async {
    final changed = await _client.rpc<bool>(
      'approve_spot',
      params: {'p_spot_id': spotId, 'p_tags': tags},
    );
    if (!changed) throw const NotFoundFailure();
  }

  /// L'RPC restituisce `false` se lo spot non esiste o non è in attesa.
  Future<void> rejectSpot(String spotId) async {
    final changed = await _client.rpc<bool>(
      'reject_spot',
      params: {'p_spot_id': spotId},
    );
    if (!changed) throw const NotFoundFailure();
  }

  /// L'RPC restituisce `false` se la chat non esiste (o non è con un canale) o
  /// l'utente era già in quello stato.
  Future<void> setChatUserBlocked(
    String chatId, {
    required bool blocked,
  }) async {
    final changed = await _client.rpc<bool>(
      'set_chat_user_blocked',
      params: {'p_chat_id': chatId, 'p_blocked': blocked},
    );
    if (!changed) throw const NotFoundFailure();
  }

  Future<bool> isChatUserBlocked(String chatId) async {
    final blocked = await _client.rpc<bool>(
      'is_chat_user_blocked',
      params: {'p_chat_id': chatId},
    );
    return blocked;
  }

  Future<List<BlockedUser>> getBlockedUsers({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'channel_blocked_users',
      params: {
        'p_channel_id': channelId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => BlockedUserDto.fromJson(row).toEntity())
        .toList();
  }

  /// L'RPC restituisce `false` se il blocco non esiste.
  Future<void> unblockChannelUser(String blockId) async {
    final removed = await _client.rpc<bool>(
      'unblock_channel_user',
      params: {'p_block_id': blockId},
    );
    if (!removed) throw const NotFoundFailure();
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
