import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/presentation/providers/channel_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/my_spots_feed.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';

part 'create_spot_controller.g.dart';

@riverpod
class CreateSpotController extends _$CreateSpotController {
  @override
  FutureOr<void> build() {}

  /// Restituisce lo spot pubblicato, oppure `null` se fallisce (l'errore è in
  /// `state`).
  Future<Spot?> submit({
    required String channelId,
    required String title,
    required String content,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(createSpotUseCaseProvider)(
        channelId: channelId,
        title: title,
        content: content,
      ),
    );
    if (!ref.mounted) return result.value;

    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return null;
    }
    state = const AsyncData(null);
    // Il feed del canale e "i miei spot" vanno ricaricati.
    ref
      ..invalidate(channelSpotsFeedProvider)
      ..invalidate(mySpotsFeedProvider);
    return result.value;
  }
}
