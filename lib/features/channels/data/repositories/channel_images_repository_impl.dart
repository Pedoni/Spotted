import 'dart:typed_data';

import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/channels/data/datasources/channel_images_remote_data_source.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/features/channels/domain/repositories/channel_images_repository.dart';

class ChannelImagesRepositoryImpl implements ChannelImagesRepository {
  const ChannelImagesRepositoryImpl(this._dataSource);

  final ChannelImagesRemoteDataSource _dataSource;

  @override
  Future<String> setImage({
    required String channelId,
    required ChannelImageKind kind,
    required Uint8List bytes,
  }) {
    return guardFailures(
      () => _dataSource.setImage(
        channelId: channelId,
        kind: kind,
        bytes: bytes,
      ),
    );
  }

  @override
  Future<void> removeImage({
    required String channelId,
    required ChannelImageKind kind,
  }) {
    return guardFailures(
      () => _dataSource.removeImage(channelId: channelId, kind: kind),
    );
  }

  @override
  Future<void> deleteFiles(List<String> paths) {
    return guardFailures(() => _dataSource.deleteFiles(paths));
  }
}
