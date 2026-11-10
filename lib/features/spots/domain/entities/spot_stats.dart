import 'package:equatable/equatable.dart';

/// Quanto uno spot è piaciuto e commentato, e se l'utente loggato ha messo
/// "mi piace". Mai chi ha messo like: i like sono anonimi.
class SpotStats extends Equatable {
  const SpotStats({
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
  });

  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  /// Stato dopo aver messo (o tolto) il like.
  SpotStats toggledLike() {
    final liked = !likedByMe;
    return SpotStats(
      likeCount: liked ? likeCount + 1 : (likeCount - 1).clamp(0, likeCount),
      commentCount: commentCount,
      likedByMe: liked,
    );
  }

  SpotStats withCommentCount(int count) => SpotStats(
    likeCount: likeCount,
    commentCount: count < 0 ? 0 : count,
    likedByMe: likedByMe,
  );

  @override
  List<Object?> get props => [likeCount, commentCount, likedByMe];
}
