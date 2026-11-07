import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/topics/data/datasources/topics_remote_data_source.dart';
import 'package:spotted/features/topics/data/repositories/topics_repository_impl.dart';
import 'package:spotted/features/topics/domain/entities/topic.dart';
import 'package:spotted/features/topics/domain/repositories/topics_repository.dart';
import 'package:spotted/features/topics/domain/usecases/get_topics.dart';

part 'topics_providers.g.dart';

@Riverpod(keepAlive: true)
TopicsRepository topicsRepository(Ref ref) {
  return TopicsRepositoryImpl(
    TopicsRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

/// L'elenco dei topic è fisso: lo carichiamo una volta sola.
@Riverpod(keepAlive: true)
Future<List<Topic>> topics(Ref ref) {
  return GetTopics(ref.watch(topicsRepositoryProvider))();
}
