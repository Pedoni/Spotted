import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/comments/domain/comment_validators.dart';
import 'package:spotted/features/comments/domain/usecases/add_comment.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeCommentsRepository repository;
  late AddComment addComment;

  setUp(() {
    repository = FakeCommentsRepository();
    addComment = AddComment(repository);
  });

  test('toglie gli spazi ai bordi del testo', () async {
    await addComment(spotId: 's1', content: '  Che bello!  \n');

    expect(repository.addCalls.single, (spotId: 's1', content: 'Che bello!'));
  });

  test('testo vuoto o di soli spazi: ValidationFailure', () async {
    await expectLater(
      addComment(spotId: 's1', content: '   '),
      throwsA(isA<ValidationFailure>()),
    );
    expect(repository.addCalls, isEmpty);
  });

  test('limite di lunghezza: 500 sì, uno in più no', () async {
    await addComment(
      spotId: 's1',
      content: 'a' * CommentValidators.maxLength,
    );
    expect(repository.addCalls, hasLength(1));

    await expectLater(
      addComment(
        spotId: 's1',
        content: 'a' * (CommentValidators.maxLength + 1),
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(repository.addCalls, hasLength(1));
  });

  group('Comment.toggledLike', () {
    test('mette il like', () {
      final comment = makeComment(1, likeCount: 2).toggledLike();

      expect(comment.likedByMe, isTrue);
      expect(comment.likeCount, 3);
    });

    test('toglie il like senza scendere sotto zero', () {
      final comment = makeComment(1, likedByMe: true).toggledLike();

      expect(comment.likedByMe, isFalse);
      expect(comment.likeCount, 0);
    });

    test('non cambia gli altri campi', () {
      final original = makeComment(1, isMine: true, likeCount: 1);

      expect(original.toggledLike().toggledLike(), original);
    });
  });
}
