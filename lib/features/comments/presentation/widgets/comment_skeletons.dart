import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/comments/domain/entities/comment.dart';
import 'package:spotted/features/comments/presentation/widgets/comment_tile.dart';

/// Scheletro di un elenco di commenti.
class CommentsSkeleton extends StatelessWidget {
  const CommentsSkeleton({this.count = 3, super.key});

  final int count;

  static const _contents = [
    'Un commento di media lunghezza, scritto su un paio di righe.',
    'Un commento corto.',
    'Un commento un po più lungo, che va a capo su più righe.',
  ];

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            CommentTile(
              comment: Comment(
                id: 'skeleton-$i',
                spotId: 'skeleton',
                content: _contents[i % _contents.length],
                createdAt: DateTime(2026),
                isSpotAuthor: false,
                isMine: false,
                authorUsername: 'username',
                likeCount: 2,
              ),
              onLike: () {},
              onDelete: () {},
            ),
        ],
      ),
    );
  }
}
