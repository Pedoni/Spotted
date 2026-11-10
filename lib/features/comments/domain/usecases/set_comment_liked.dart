import 'package:spotted/features/comments/domain/repositories/comments_repository.dart';

class SetCommentLiked {
  const SetCommentLiked(this._repository);

  final CommentsRepository _repository;

  Future<void> call(String commentId, {required bool liked}) {
    return _repository.setCommentLiked(commentId, liked: liked);
  }
}
