import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/data/models/create_spot_dto.dart';
import 'package:spotted/features/spots/data/models/my_spot_dto.dart';
import 'package:spotted/features/spots/data/models/spot_dto.dart';
import 'package:spotted/features/spots/domain/entities/my_spot.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';
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

  /// Usa l'RPC `channel_spots_page`: gli spot arrivano con i conteggi di like
  /// e commenti, senza mai `author_id`.
  Future<List<Spot>> getChannelSpots({
    required String channelId,
    required int offset,
    required int limit,
    String? query,
  }) async {
    final text = SpotValidators.searchText(query);
    final rows = await _client.rpc<List<dynamic>>(
      'channel_spots_page',
      params: {
        'p_channel_id': channelId,
        'p_limit': limit,
        'p_offset': offset,
        // Solo se si cerca: senza ricerca la richiesta è quella di sempre.
        'p_query': ?text,
      },
    );
    return _toSpots(rows);
  }

  Future<Spot> getSpot(String spotId) async {
    final rows = await _client.rpc<List<dynamic>>(
      'spot_detail',
      params: {'p_spot_id': spotId},
    );
    final spots = _toSpots(rows);
    if (spots.isEmpty) throw const NotFoundFailure();
    return spots.single;
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

  Future<void> setSpotLiked(String spotId, {required bool liked}) async {
    await _client.rpc<void>(
      'set_spot_liked',
      params: {'p_spot_id': spotId, 'p_liked': liked},
    );
  }

  List<Spot> _toSpots(List<dynamic> rows) => rows
      .cast<Map<String, dynamic>>()
      .map((row) => SpotDto.fromJson(row).toEntity())
      .toList();
}
