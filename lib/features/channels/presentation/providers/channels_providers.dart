import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/config/env.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/channels/data/datasources/channel_images_remote_data_source.dart';
import 'package:spotted/features/channels/data/datasources/channels_remote_data_source.dart';
import 'package:spotted/features/channels/data/image_channel_image_processor.dart';
import 'package:spotted/features/channels/data/repositories/channel_images_repository_impl.dart';
import 'package:spotted/features/channels/data/repositories/channels_repository_impl.dart';
import 'package:spotted/features/channels/domain/channel_image_processor.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channel_images_repository.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';
import 'package:spotted/features/channels/domain/usecases/create_channel.dart';
import 'package:spotted/features/channels/domain/usecases/delete_channel.dart';
import 'package:spotted/features/channels/domain/usecases/get_channel_by_slug.dart';
import 'package:spotted/features/channels/domain/usecases/get_channels.dart';
import 'package:spotted/features/channels/domain/usecases/get_my_channels.dart';
import 'package:spotted/features/channels/domain/usecases/remove_channel_image.dart';
import 'package:spotted/features/channels/domain/usecases/set_channel_image.dart';
import 'package:spotted/features/channels/domain/usecases/update_channel.dart';
import 'package:spotted/features/channels/presentation/services/channel_image_cropper.dart';
import 'package:spotted/features/channels/presentation/services/channel_image_picker.dart';

part 'channels_providers.g.dart';

@Riverpod(keepAlive: true)
ChannelsRepository channelsRepository(Ref ref) {
  return ChannelsRepositoryImpl(
    ChannelsRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
GetChannels getChannelsUseCase(Ref ref) {
  return GetChannels(ref.watch(channelsRepositoryProvider));
}

@riverpod
CreateChannel createChannelUseCase(Ref ref) {
  return CreateChannel(ref.watch(channelsRepositoryProvider));
}

@riverpod
UpdateChannel updateChannelUseCase(Ref ref) {
  return UpdateChannel(ref.watch(channelsRepositoryProvider));
}

@riverpod
DeleteChannel deleteChannelUseCase(Ref ref) {
  return DeleteChannel(ref.watch(channelsRepositoryProvider));
}

@riverpod
Future<Channel> channelDetail(Ref ref, String slug) {
  return GetChannelBySlug(ref.watch(channelsRepositoryProvider))(slug);
}

@riverpod
Future<List<Channel>> myChannels(Ref ref) {
  return GetMyChannels(ref.watch(channelsRepositoryProvider))();
}

@Riverpod(keepAlive: true)
ChannelImagesRepository channelImagesRepository(Ref ref) {
  return ChannelImagesRepositoryImpl(
    ChannelImagesRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@Riverpod(keepAlive: true)
ChannelImageProcessor channelImageProcessor(Ref ref) {
  return const ImageChannelImageProcessor();
}

@riverpod
SetChannelImage setChannelImageUseCase(Ref ref) {
  return SetChannelImage(
    ref.watch(channelImagesRepositoryProvider),
    ref.watch(channelImageProcessorProvider),
  );
}

@riverpod
RemoveChannelImage removeChannelImageUseCase(Ref ref) {
  return RemoveChannelImage(ref.watch(channelImagesRepositoryProvider));
}

/// Da un percorso nello storage all'indirizzo pubblico dell'immagine (o `null`
/// se non c'è il percorso).
typedef ChannelImageUrlBuilder = String? Function(String? path);

/// Il bucket è pubblico: l'indirizzo si costruisce senza chiedere niente a
/// nessuno. Senza la configurazione di Supabase (nei test) non c'è.
@Riverpod(keepAlive: true)
ChannelImageUrlBuilder channelImageUrl(Ref ref) {
  return (path) {
    if (path == null || !Env.isConfigured) return null;
    return '${Env.supabaseUrl}/storage/v1/object/public/'
        '$channelImagesBucket/$path';
  };
}

@Riverpod(keepAlive: true)
ChannelImagePicker channelImagePicker(Ref ref) => DeviceChannelImagePicker();

@Riverpod(keepAlive: true)
ChannelImageCropper channelImageCropper(Ref ref) {
  return const PageChannelImageCropper();
}
