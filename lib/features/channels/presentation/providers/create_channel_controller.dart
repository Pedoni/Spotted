import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/features/channels/domain/entities/channel.dart';
import 'package:spotted/features/channels/presentation/providers/channels_feed.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';

part 'create_channel_controller.g.dart';

@riverpod
class CreateChannelController extends _$CreateChannelController {
  @override
  FutureOr<void> build() {}

  /// Restituisce il canale creato, oppure `null` se fallisce (l'errore è in
  /// `state`).
  Future<Channel?> submit({
    required String name,
    String? description,
    String? place,
    String? topicId,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(createChannelUseCaseProvider)(
        name: name,
        description: description,
        place: place,
        topicId: topicId,
      ),
    );
    if (!ref.mounted) return result.value;

    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return null;
    }
    state = const AsyncData(null);
    // La lista e "i miei canali" vanno ricaricate.
    ref
      ..invalidate(channelsFeedProvider)
      ..invalidate(myChannelsProvider);
    return result.value;
  }
}
