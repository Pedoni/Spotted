import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/comments/domain/entities/comment.dart';
import 'package:spotted/features/comments/presentation/providers/comments_providers.dart';

part 'spot_comments_feed.g.dart';

const commentsPageSize = 20;

/// Commenti di uno spot, dal più recente (infinite scroll, [commentsPageSize]
/// per pagina). Un'istanza per spot.
@riverpod
class SpotCommentsFeed extends _$SpotCommentsFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  /// Commenti con un "mi piace" in corso: un secondo tocco viene ignorato.
  final _liking = <String>{};

  @override
  Future<PagedList<Comment>> build(String spotId) async {
    _generation++;
    final items = await ref.read(getSpotCommentsUseCaseProvider)(
      spotId: spotId,
      offset: 0,
      limit: commentsPageSize,
    );
    return PagedList(items: items, hasMore: items.length == commentsPageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final more = await ref.read(getSpotCommentsUseCaseProvider)(
        spotId: spotId,
        offset: current.items.length,
        limit: commentsPageSize,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        PagedList(
          items: [...current.items, ...more],
          hasMore: more.length == commentsPageSize,
        ),
      );
    } on Exception {
      if (ref.mounted && generation == _generation) {
        state = AsyncData(
          current.copyWith(isLoadingMore: false, loadMoreFailed: true),
        );
      }
    }
  }

  /// Pubblica un commento e lo mette in cima alla lista. Se fallisce rilancia
  /// l'errore.
  Future<Comment> add(String content) async {
    final comment = await ref.read(addCommentUseCaseProvider)(
      spotId: spotId,
      content: content,
    );
    final current = state.value;
    if (ref.mounted && current != null) {
      state = AsyncData(current.copyWith(items: [comment, ...current.items]));
    }
    return comment;
  }

  /// Cancella un commento. Se fallisce rilancia l'errore e la lista non
  /// cambia.
  Future<void> delete(String commentId) async {
    await ref.read(deleteCommentUseCaseProvider)(commentId);
    final current = state.value;
    if (ref.mounted && current != null) {
      state = AsyncData(
        current.copyWith(
          items: [
            for (final comment in current.items)
              if (comment.id != commentId) comment,
          ],
        ),
      );
    }
  }

  /// Mette o toglie il like a un commento. Aggiorna subito la lista; se la
  /// richiesta fallisce torna al valore precedente e rilancia l'errore.
  Future<void> toggleLike(String commentId) async {
    final current = state.value;
    if (current == null || !_liking.add(commentId)) return;

    final original = current.items.where((c) => c.id == commentId).firstOrNull;
    if (original == null) {
      _liking.remove(commentId);
      return;
    }

    final toggled = original.toggledLike();
    _replace(commentId, toggled);
    try {
      await ref.read(setCommentLikedUseCaseProvider)(
        commentId,
        liked: toggled.likedByMe,
      );
    } on Exception {
      _replace(commentId, original);
      rethrow;
    } finally {
      _liking.remove(commentId);
    }
  }

  void _replace(String commentId, Comment comment) {
    final current = state.value;
    if (!ref.mounted || current == null) return;
    state = AsyncData(
      current.copyWith(
        items: [
          for (final item in current.items)
            if (item.id == commentId) comment else item,
        ],
      ),
    );
  }
}
