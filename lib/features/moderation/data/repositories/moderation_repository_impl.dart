import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/moderation/data/datasources/moderation_remote_data_source.dart';
import 'package:spotted/features/moderation/domain/entities/moderation_status.dart';
import 'package:spotted/features/moderation/domain/entities/spot_author.dart';
import 'package:spotted/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  const ModerationRepositoryImpl(this._dataSource);

  final ModerationRemoteDataSource _dataSource;

  @override
  Future<bool> isChannelOwner(String channelId) {
    return guardFailures(() => _dataSource.isChannelOwner(channelId));
  }

  @override
  Future<SpotAuthor> getSpotAuthor(String spotId) {
    return guardFailures(() => _dataSource.getSpotAuthor(spotId));
  }

  @override
  Future<void> setSpotStatus(String spotId, ModerationStatus status) {
    return guardFailures(() => _dataSource.setSpotStatus(spotId, status));
  }

  @override
  Future<void> setCommentHidden(String commentId, {required bool hidden}) {
    return guardFailures(
      () => _dataSource.setCommentHidden(commentId, hidden: hidden),
    );
  }

  @override
  Future<List<Spot>> getHiddenSpots({
    required String channelId,
    required int offset,
    required int limit,
  }) {
    return guardFailures(
      () => _dataSource.getHiddenSpots(
        channelId: channelId,
        offset: offset,
        limit: limit,
      ),
    );
  }
}
