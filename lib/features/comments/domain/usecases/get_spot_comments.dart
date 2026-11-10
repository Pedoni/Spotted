import 'package:spotted/features/comments/domain/entities/comment.dart';
import 'package:spotted/features/comments/domain/repositories/comments_repository.dart';

class GetSpotComments {
  const GetSpotComments(this._repository);

  final CommentsRepository _repository;

  Future<List<Comment>> call({
    required String spotId,
    required int offset,
    required int limit,
  }) {
    return _repository.getSpotComments(
      spotId: spotId,
      offset: offset,
      limit: limit,
    );
  }
}
