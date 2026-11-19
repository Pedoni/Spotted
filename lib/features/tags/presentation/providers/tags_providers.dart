import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/tags/data/datasources/tags_remote_data_source.dart';
import 'package:spotted/features/tags/data/repositories/tags_repository_impl.dart';
import 'package:spotted/features/tags/domain/entities/tag.dart';
import 'package:spotted/features/tags/domain/repositories/tags_repository.dart';
import 'package:spotted/features/tags/domain/usecases/get_all_tags.dart';
import 'package:spotted/features/tags/domain/usecases/get_channel_tags.dart';

part 'tags_providers.g.dart';

@Riverpod(keepAlive: true)
TagsRepository tagsRepository(Ref ref) {
  return TagsRepositoryImpl(
    TagsRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
GetAllTags getAllTagsUseCase(Ref ref) {
  return GetAllTags(ref.watch(tagsRepositoryProvider));
}

@riverpod
GetChannelTags getChannelTagsUseCase(Ref ref) {
  return GetChannelTags(ref.watch(tagsRepositoryProvider));
}

/// Il nome visibile di ogni tag, per nome tecnico. L'elenco è uguale per tutti
/// e senza dati dell'utente: una volta caricato resta in memoria (`keepAlive`
/// solo a caricamento riuscito); se fallisce non si ricorda l'errore e la
/// volta dopo si riprova.
@riverpod
Future<Map<String, String>> tagLabels(Ref ref) async {
  final tags = await ref.watch(getAllTagsUseCaseProvider)();
  ref.keepAlive();
  return {for (final tag in tags) tag.slug: tag.label};
}

/// I tag tra cui scegliere in un canale (generici e dell'argomento).
@riverpod
Future<List<Tag>> channelTags(Ref ref, String channelId) {
  return ref.watch(getChannelTagsUseCaseProvider)(channelId);
}
