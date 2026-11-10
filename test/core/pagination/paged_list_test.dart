import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/pagination/paged_list.dart';

void main() {
  test('copyWith cambia solo i campi indicati', () {
    const list = PagedList<int>(items: [1, 2], hasMore: true);

    final loading = list.copyWith(isLoadingMore: true);

    expect(loading.items, [1, 2]);
    expect(loading.hasMore, isTrue);
    expect(loading.isLoadingMore, isTrue);
    expect(loading.loadMoreFailed, isFalse);
  });

  test('due liste con gli stessi dati sono uguali', () {
    expect(
      const PagedList<int>(items: [1], hasMore: false),
      const PagedList<int>(items: [1], hasMore: false),
    );
  });
}
