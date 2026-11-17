import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/news/data/datasources/news_remote_data_source.dart';
import 'package:spotted/features/news/data/repositories/news_repository_impl.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';
import 'package:spotted/features/news/domain/repositories/news_repository.dart';
import 'package:spotted/features/news/domain/usecases/create_news.dart';
import 'package:spotted/features/news/domain/usecases/delete_news.dart';
import 'package:spotted/features/news/domain/usecases/get_channel_news.dart';
import 'package:spotted/features/news/domain/usecases/get_followed_news.dart';
import 'package:spotted/features/news/domain/usecases/get_news.dart';
import 'package:spotted/features/news/domain/usecases/update_news.dart';

part 'news_providers.g.dart';

@Riverpod(keepAlive: true)
NewsRepository newsRepository(Ref ref) {
  return NewsRepositoryImpl(
    NewsRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
GetChannelNews getChannelNewsUseCase(Ref ref) {
  return GetChannelNews(ref.watch(newsRepositoryProvider));
}

@riverpod
GetFollowedNews getFollowedNewsUseCase(Ref ref) {
  return GetFollowedNews(ref.watch(newsRepositoryProvider));
}

@riverpod
GetNews getNewsUseCase(Ref ref) => GetNews(ref.watch(newsRepositoryProvider));

@riverpod
CreateNews createNewsUseCase(Ref ref) {
  return CreateNews(ref.watch(newsRepositoryProvider));
}

@riverpod
UpdateNews updateNewsUseCase(Ref ref) {
  return UpdateNews(ref.watch(newsRepositoryProvider));
}

@riverpod
DeleteNews deleteNewsUseCase(Ref ref) {
  return DeleteNews(ref.watch(newsRepositoryProvider));
}

/// Una news (pagina di dettaglio).
@riverpod
Future<ChannelNews> newsDetail(Ref ref, String newsId) {
  return ref.watch(getNewsUseCaseProvider)(newsId);
}
