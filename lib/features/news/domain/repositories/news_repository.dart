import 'package:spotted/features/news/domain/entities/channel_news.dart';

/// Contratto delle news dei canali. Le implementazioni lanciano un `Failure`.
abstract interface class NewsRepository {
  /// Pagina di news di un canale, dalla più recente.
  Future<List<ChannelNews>> getChannelNews({
    required String channelId,
    required int offset,
    required int limit,
  });

  /// Le news dei canali seguiti, dalla più recente.
  Future<List<ChannelNews>> getFollowedNews({
    required int offset,
    required int limit,
  });

  /// Una news. Lancia `NotFoundFailure` se non esiste.
  Future<ChannelNews> getNews(String newsId);

  /// Pubblica una news. Solo il proprietario del canale (altrimenti
  /// `PermissionFailure`).
  Future<ChannelNews> createNews({
    required String channelId,
    required String title,
    required String body,
  });

  /// Modifica titolo e testo. Lancia `NotFoundFailure` se la news non esiste e
  /// `PermissionFailure` se chi chiama non è il proprietario.
  Future<ChannelNews> updateNews({
    required String newsId,
    required String title,
    required String body,
  });

  /// Elimina una news. Lancia `NotFoundFailure` se non esiste e
  /// `PermissionFailure` se chi chiama non è il proprietario.
  Future<void> deleteNews(String newsId);
}
