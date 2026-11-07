import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/channels/data/datasources/channels_remote_data_source.dart';
import 'package:spotted/features/channels/data/repositories/channels_repository_impl.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/domain/repositories/channels_repository.dart';
import 'package:spotted/features/channels/domain/usecases/create_channel.dart';
import 'package:spotted/features/channels/domain/usecases/get_channel_by_slug.dart';
import 'package:spotted/features/channels/domain/usecases/get_channels.dart';
import 'package:spotted/features/channels/domain/usecases/get_my_channels.dart';

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
Future<Channel> channelDetail(Ref ref, String slug) {
  return GetChannelBySlug(ref.watch(channelsRepositoryProvider))(slug);
}

@riverpod
Future<List<Channel>> myChannels(Ref ref) {
  return GetMyChannels(ref.watch(channelsRepositoryProvider))();
}
