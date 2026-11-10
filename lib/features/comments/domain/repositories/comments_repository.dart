import 'package:spotted/features/comments/domain/entities/comment.dart';

/// Contratto dei commenti. Le implementazioni lanciano un `Failure`.
abstract interface class CommentsRepository {
  /// Pagina di commenti di uno spot, dal più recente.
  Future<List<Comment>> getSpotComments({
    required String spotId,
    required int offset,
    required int limit,
  });

  /// Pubblica un commento. Lancia `NotFoundFailure` se lo spot non esiste.
  Future<Comment> addComment({required String spotId, required String content});

  /// Cancella un commento dell'utente. Lancia `NotFoundFailure` se non esiste
  /// o non è suo.
  Future<void> deleteComment(String commentId);

  /// Mette o toglie il "mi piace" dell'utente loggato.
  Future<void> setCommentLiked(String commentId, {required bool liked});
}
