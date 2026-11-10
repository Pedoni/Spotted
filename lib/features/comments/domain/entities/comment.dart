import 'package:equatable/equatable.dart';

/// Un commento a uno spot. I commenti non sono anonimi: si vede lo username
/// dell'autore, tranne quando a commentare è l'autore dello spot (compare come
/// "Autore del post", senza nome).
class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.spotId,
    required this.content,
    required this.createdAt,
    required this.isSpotAuthor,
    required this.isMine,
    this.authorUsername,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String spotId;
  final String content;
  final DateTime createdAt;

  /// `null` quando [isSpotAuthor] è vero.
  final String? authorUsername;
  final bool isSpotAuthor;

  /// Il commento è dell'utente loggato (può cancellarlo).
  final bool isMine;
  final int likeCount;
  final bool likedByMe;

  /// Stato dopo aver messo (o tolto) il like.
  Comment toggledLike() {
    final liked = !likedByMe;
    return Comment(
      id: id,
      spotId: spotId,
      content: content,
      createdAt: createdAt,
      isSpotAuthor: isSpotAuthor,
      isMine: isMine,
      authorUsername: authorUsername,
      likeCount: liked ? likeCount + 1 : (likeCount - 1).clamp(0, likeCount),
      likedByMe: liked,
    );
  }

  @override
  List<Object?> get props => [
    id,
    spotId,
    content,
    createdAt,
    authorUsername,
    isSpotAuthor,
    isMine,
    likeCount,
    likedByMe,
  ];
}
