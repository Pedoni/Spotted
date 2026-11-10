import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/comments/data/models/comment_dto.dart';
import 'package:spotted/features/comments/domain/entities/comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// I commenti si leggono e scrivono solo con RPC: `comments.author_id` non è
/// leggibile dai client (confrontato con l'autore dello spot lo rivelerebbe).
class CommentsRemoteDataSource {
  const CommentsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Comment>> getSpotComments({
    required String spotId,
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'spot_comments',
      params: {'p_spot_id': spotId, 'p_limit': limit, 'p_offset': offset},
    );
    return _toComments(rows);
  }

  /// L'RPC non restituisce righe se lo spot non esiste o non è pubblicato.
  Future<Comment> addComment({
    required String spotId,
    required String content,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'add_comment',
      params: {'p_spot_id': spotId, 'p_content': content},
    );
    final comments = _toComments(rows);
    if (comments.isEmpty) throw const NotFoundFailure();
    return comments.single;
  }

  /// L'RPC restituisce `false` se il commento non esiste o non è dell'utente.
  Future<void> deleteComment(String commentId) async {
    final deleted = await _client.rpc<bool>(
      'delete_comment',
      params: {'p_comment_id': commentId},
    );
    if (!deleted) throw const NotFoundFailure();
  }

  Future<void> setCommentLiked(String commentId, {required bool liked}) async {
    await _client.rpc<void>(
      'set_comment_liked',
      params: {'p_comment_id': commentId, 'p_liked': liked},
    );
  }

  List<Comment> _toComments(List<dynamic> rows) => rows
      .cast<Map<String, dynamic>>()
      .map((row) => CommentDto.fromJson(row).toEntity())
      .toList();
}
