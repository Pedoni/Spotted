import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/comments/data/datasources/comments_remote_data_source.dart';
import 'package:spotted/features/comments/domain/entities/comment.dart';
import 'package:spotted/features/comments/domain/repositories/comments_repository.dart';

class CommentsRepositoryImpl implements CommentsRepository {
  const CommentsRepositoryImpl(this._dataSource);

  final CommentsRemoteDataSource _dataSource;

  @override
  Future<List<Comment>> getSpotComments({
    required String spotId,
    required int offset,
    required int limit,
  }) {
    return guardFailures(
      () => _dataSource.getSpotComments(
        spotId: spotId,
        offset: offset,
        limit: limit,
      ),
    );
  }

  @override
  Future<Comment> addComment({
    required String spotId,
    required String content,
  }) {
    return guardFailures(
      () => _dataSource.addComment(spotId: spotId, content: content),
    );
  }

  @override
  Future<void> deleteComment(String commentId) {
    return guardFailures(() => _dataSource.deleteComment(commentId));
  }

  @override
  Future<void> setCommentLiked(String commentId, {required bool liked}) {
    return guardFailures(
      () => _dataSource.setCommentLiked(commentId, liked: liked),
    );
  }
}
