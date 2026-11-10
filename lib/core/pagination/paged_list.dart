import 'package:equatable/equatable.dart';

/// Elementi caricati finora in una lista a scroll infinito.
class PagedList<T> extends Equatable {
  const PagedList({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<T> items;
  final bool hasMore;
  final bool isLoadingMore;

  /// L'ultimo caricamento di una pagina successiva è fallito: la UI mostra
  /// "Riprova" invece di ritentare da sola in loop.
  final bool loadMoreFailed;

  PagedList<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return PagedList(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }

  @override
  List<Object?> get props => [items, hasMore, isLoadingMore, loadMoreFailed];
}
