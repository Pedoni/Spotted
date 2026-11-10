import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/data/models/create_spot_dto.dart';
import 'package:spotted/features/spots/data/models/my_spot_dto.dart';
import 'package:spotted/features/spots/data/models/spot_dto.dart';
import 'package:spotted/features/spots/domain/entities/my_spot.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpotsRemoteDataSource {
  /// [currentUserId] permette di fornire l'id utente nei test; di default è
  /// quello della sessione Supabase.
  SpotsRemoteDataSource(
    this._client, {
    String? Function()? currentUserId,
  }) : _currentUserId = currentUserId ?? (() => _client.auth.currentUser?.id);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  Future<List<Spot>> getChannelSpots({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    final rows = await _client
        .from('spots')
        .select(spotColumns)
        .eq('channel_id', channelId)
        .order('created_at', ascending: false)
        .order('id')
        .range(offset, offset + limit - 1);
    return rows.map((row) => SpotDto.fromJson(row).toEntity()).toList();
  }

  /// Usa l'RPC `my_spots_page`: `author_id` non è leggibile dalla tabella.
  Future<List<MySpot>> getMySpots({
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'my_spots_page',
      params: {'p_limit': limit, 'p_offset': offset},
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => MySpotDto.fromJson(row).toEntity())
        .toList();
  }

  Future<Spot> createSpot({
    required String channelId,
    required String title,
    required String content,
  }) async {
    final authorId = _currentUserId();
    if (authorId == null) {
      throw const AuthFailure(AuthFailureReason.unknown);
    }
    // `select(spotColumns)` evita di chiedere `author_id` in `returning`.
    final dto = CreateSpotDto(
      authorId: authorId,
      channelId: channelId,
      title: title,
      content: content,
    );
    final row = await _client
        .from('spots')
        .insert(dto.toJson())
        .select(spotColumns)
        .single();
    return SpotDto.fromJson(row).toEntity();
  }

  /// La policy RLS lascia cancellare solo gli spot dell'autore: se non c'è
  /// nessuna riga cancellata lo spot non esiste o non è suo.
  Future<void> deleteSpot(String spotId) async {
    final rows = await _client
        .from('spots')
        .delete()
        .eq('id', spotId)
        .select('id');
    if (rows.isEmpty) throw const NotFoundFailure();
  }
}
