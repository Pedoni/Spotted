import 'package:spotted/features/comments/domain/repositories/comments_repository.dart';

class DeleteComment {
  const DeleteComment(this._repository);

  final CommentsRepository _repository;

  Future<void> call(String commentId) => _repository.deleteComment(commentId);
}
