import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/spots/data/datasources/spots_remote_data_source.dart';
import 'package:spotted/features/spots/domain/entities/my_spot.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';

class SpotsRepositoryImpl implements SpotsRepository {
  const SpotsRepositoryImpl(this._dataSource);

  final SpotsRemoteDataSource _dataSource;

  @override
  Future<List<Spot>> getChannelSpots({
    required String channelId,
    required int offset,
    required int limit,
  }) {
    return guardFailures(
      () => _dataSource.getChannelSpots(
        channelId: channelId,
        offset: offset,
        limit: limit,
      ),
    );
  }

  @override
  Future<Spot> getSpot(String spotId) {
    return guardFailures(() => _dataSource.getSpot(spotId));
  }

  @override
  Future<List<MySpot>> getMySpots({required int offset, required int limit}) {
    return guardFailures(
      () => _dataSource.getMySpots(offset: offset, limit: limit),
    );
  }

  @override
  Future<Spot> createSpot({
    required String channelId,
    required String title,
    required String content,
  }) {
    return guardFailures(
      () => _dataSource.createSpot(
        channelId: channelId,
        title: title,
        content: content,
      ),
    );
  }

  @override
  Future<void> deleteSpot(String spotId) {
    return guardFailures(() => _dataSource.deleteSpot(spotId));
  }

  @override
  Future<void> setSpotLiked(String spotId, {required bool liked}) {
    return guardFailures(
      () => _dataSource.setSpotLiked(spotId, liked: liked),
    );
  }
}
