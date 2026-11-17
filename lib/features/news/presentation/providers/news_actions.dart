import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/presentation/providers/channel_news_feed.dart';
import 'package:spotted/features/news/presentation/providers/followed_news_feed.dart';
import 'package:spotted/features/news/presentation/providers/news_providers.dart';

part 'news_actions.g.dart';

/// Pubblicazione, modifica ed eliminazione delle news, con le liste da
/// ricaricare. Resta vivo (`keepAlive`), come `ChannelActions`: dopo
/// l'eliminazione la pagina se ne va e, se il provider si distruggesse a metà,
/// le liste non verrebbero aggiornate. Non tiene dati dell'utente.
@Riverpod(keepAlive: true)
class NewsActions extends _$NewsActions {
  @override
  void build() {}

  /// Pubblica una news. Se fallisce rilancia l'errore e non cambia niente.
  Future<ChannelNews> create({
    required String channelId,
    required String title,
    required String body,
  }) async {
    final created = await ref.read(createNewsUseCaseProvider)(
      channelId: channelId,
      title: title,
      body: body,
    );
    if (ref.mounted) _refreshLists();
    return created;
  }

  Future<ChannelNews> update({
    required String newsId,
    required String title,
    required String body,
  }) async {
    final updated = await ref.read(updateNewsUseCaseProvider)(
      newsId: newsId,
      title: title,
      body: body,
    );
    if (ref.mounted) {
      _refreshLists();
      ref.invalidate(newsDetailProvider(newsId));
    }
    return updated;
  }

  Future<void> delete(String newsId) async {
    await ref.read(deleteNewsUseCaseProvider)(newsId);
    // Il dettaglio non si ricarica: la pagina se ne va e la news non c'è più.
    if (ref.mounted) _refreshLists();
  }

  /// Le liste che mostrano le news: quella del canale e quella della Home.
  void _refreshLists() {
    ref
      ..invalidate(channelNewsFeedProvider)
      ..invalidate(followedNewsFeedProvider);
  }
}
