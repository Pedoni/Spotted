import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';

class SetCommentHidden {
  const SetCommentHidden(this._repository);

  final ModerationRepository _repository;

  Future<void> call(String commentId, {required bool hidden}) =>
      _repository.setCommentHidden(commentId, hidden: hidden);
}
