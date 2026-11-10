import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/comments/data/datasources/comments_remote_data_source.dart';
import 'package:spotted/features/comments/data/repositories/comments_repository_impl.dart';
import 'package:spotted/features/comments/domain/repositories/comments_repository.dart';
import 'package:spotted/features/comments/domain/usecases/add_comment.dart';
import 'package:spotted/features/comments/domain/usecases/delete_comment.dart';
import 'package:spotted/features/comments/domain/usecases/get_spot_comments.dart';
import 'package:spotted/features/comments/domain/usecases/set_comment_liked.dart';

part 'comments_providers.g.dart';

@Riverpod(keepAlive: true)
CommentsRepository commentsRepository(Ref ref) {
  return CommentsRepositoryImpl(
    CommentsRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
GetSpotComments getSpotCommentsUseCase(Ref ref) {
  return GetSpotComments(ref.watch(commentsRepositoryProvider));
}

@riverpod
AddComment addCommentUseCase(Ref ref) {
  return AddComment(ref.watch(commentsRepositoryProvider));
}

@riverpod
DeleteComment deleteCommentUseCase(Ref ref) {
  return DeleteComment(ref.watch(commentsRepositoryProvider));
}

@riverpod
SetCommentLiked setCommentLikedUseCase(Ref ref) {
  return SetCommentLiked(ref.watch(commentsRepositoryProvider));
}
