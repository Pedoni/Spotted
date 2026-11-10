import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/comments/domain/comment_validators.dart';
import 'package:spotted/features/comments/domain/entities/comment.dart';
import 'package:spotted/features/comments/domain/repositories/comments_repository.dart';

class AddComment {
  const AddComment(this._repository);

  final CommentsRepository _repository;

  /// Valida il testo (togliendo gli spazi ai bordi) e pubblica.
  Future<Comment> call({
    required String spotId,
    required String content,
  }) async {
    if (!CommentValidators.isValid(content)) throw const ValidationFailure();
    return _repository.addComment(spotId: spotId, content: content.trim());
  }
}
