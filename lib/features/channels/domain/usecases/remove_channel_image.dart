import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';
import 'package:spotted/features/channels/domain/repositories/channel_images_repository.dart';

/// Toglie la foto o la copertina di un canale: torna quella di default.
class RemoveChannelImage {
  const RemoveChannelImage(this._repository);

  final ChannelImagesRepository _repository;

  Future<void> call({
    required String channelId,
    required ChannelImageKind kind,
  }) {
    return _repository.removeImage(channelId: channelId, kind: kind);
  }
}
