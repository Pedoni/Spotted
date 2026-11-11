import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/moderation/data/datasources/moderation_remote_data_source.dart';
import 'package:spotted/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:spotted/features/moderation/domain/entities/moderation_status.dart';
import 'package:spotted/features/moderation/domain/entities/spot_author.dart';
import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:spotted/features/moderation/domain/usecases/get_hidden_spots.dart';
import 'package:spotted/features/moderation/domain/usecases/get_spot_author.dart';
import 'package:spotted/features/moderation/domain/usecases/is_channel_owner.dart';
import 'package:spotted/features/moderation/domain/usecases/set_comment_hidden.dart';
import 'package:spotted/features/moderation/domain/usecases/set_spot_status.dart';
import 'package:spotted/features/moderation/presentation/providers/hidden_spots_feed.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/presentation/providers/channel_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/my_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';

part 'moderation_providers.g.dart';

@Riverpod(keepAlive: true)
ModerationRepository moderationRepository(Ref ref) {
  return ModerationRepositoryImpl(
    ModerationRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
IsChannelOwner isChannelOwnerUseCase(Ref ref) {
  return IsChannelOwner(ref.watch(moderationRepositoryProvider));
}

@riverpod
GetSpotAuthor getSpotAuthorUseCase(Ref ref) {
  return GetSpotAuthor(ref.watch(moderationRepositoryProvider));
}

@riverpod
SetSpotStatus setSpotStatusUseCase(Ref ref) {
  return SetSpotStatus(ref.watch(moderationRepositoryProvider));
}

@riverpod
SetCommentHidden setCommentHiddenUseCase(Ref ref) {
  return SetCommentHidden(ref.watch(moderationRepositoryProvider));
}

@riverpod
GetHiddenSpots getHiddenSpotsUseCase(Ref ref) {
  return GetHiddenSpots(ref.watch(moderationRepositoryProvider));
}

/// L'utente loggato è il proprietario del canale (mostra gli strumenti di
/// moderazione). Se la richiesta fallisce gli strumenti restano nascosti.
@riverpod
Future<bool> isChannelOwner(Ref ref, String channelId) {
  return ref.watch(isChannelOwnerUseCaseProvider)(channelId);
}

/// L'autore di uno spot, visibile solo al proprietario del canale.
@riverpod
Future<SpotAuthor> spotAuthor(Ref ref, String spotId) {
  return ref.watch(getSpotAuthorUseCaseProvider)(spotId);
}

/// Cambia lo stato di uno spot e aggiorna le liste in cui compare. Resta vivo
/// (`keepAlive`): nessuno lo ascolta, e senza si distruggerebbe a metà
/// dell'operazione senza aggiornare le liste.
@Riverpod(keepAlive: true)
class SpotModeration extends _$SpotModeration {
  @override
  void build() {}

  /// Nasconde, ripristina o rimuove [spot]. Se fallisce rilancia l'errore e
  /// non cambia niente.
  Future<void> setStatus(Spot spot, ModerationStatus status) async {
    await ref.read(setSpotStatusUseCaseProvider)(spot.id, status);
    if (!ref.mounted) return;
    ref
      ..invalidate(spotDetailProvider(spot.id))
      ..invalidate(channelSpotsFeedProvider(spot.channelId))
      ..invalidate(hiddenSpotsFeedProvider(spot.channelId))
      ..invalidate(mySpotsFeedProvider);
  }
}
