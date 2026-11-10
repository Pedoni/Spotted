import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';

void main() {
  test('toggledLike mette il like e aggiunge uno', () {
    const stats = SpotStats(likeCount: 3, commentCount: 2);

    final liked = stats.toggledLike();

    expect(liked.likedByMe, isTrue);
    expect(liked.likeCount, 4);
    expect(liked.commentCount, 2);
  });

  test('toggledLike toglie il like e sottrae uno', () {
    const stats = SpotStats(likeCount: 3, likedByMe: true);

    final unliked = stats.toggledLike();

    expect(unliked.likedByMe, isFalse);
    expect(unliked.likeCount, 2);
  });

  test('i like non scendono sotto zero', () {
    const stats = SpotStats(likedByMe: true);

    expect(stats.toggledLike().likeCount, 0);
  });

  test('withCommentCount cambia solo i commenti e non va sotto zero', () {
    const stats = SpotStats(likeCount: 1, likedByMe: true);

    expect(stats.withCommentCount(5).commentCount, 5);
    expect(stats.withCommentCount(5).likeCount, 1);
    expect(stats.withCommentCount(-1).commentCount, 0);
  });
}
