import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/spots/data/datasources/spots_remote_data_source.dart';
import 'package:spotted/features/spots/data/repositories/spots_repository_impl.dart';
import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';
import 'package:spotted/features/spots/domain/usecases/create_spot.dart';
import 'package:spotted/features/spots/domain/usecases/delete_spot.dart';
import 'package:spotted/features/spots/domain/usecases/get_channel_spots.dart';
import 'package:spotted/features/spots/domain/usecases/get_my_spots.dart';

part 'spots_providers.g.dart';

@Riverpod(keepAlive: true)
SpotsRepository spotsRepository(Ref ref) {
  return SpotsRepositoryImpl(
    SpotsRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
GetChannelSpots getChannelSpotsUseCase(Ref ref) {
  return GetChannelSpots(ref.watch(spotsRepositoryProvider));
}

@riverpod
GetMySpots getMySpotsUseCase(Ref ref) {
  return GetMySpots(ref.watch(spotsRepositoryProvider));
}

@riverpod
CreateSpot createSpotUseCase(Ref ref) {
  return CreateSpot(ref.watch(spotsRepositoryProvider));
}

@riverpod
DeleteSpot deleteSpotUseCase(Ref ref) {
  return DeleteSpot(ref.watch(spotsRepositoryProvider));
}
