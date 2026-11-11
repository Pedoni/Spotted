import 'package:spotted/features/moderation/domain/entities/moderation_status.dart';
import 'package:spotted/features/moderation/domain/entities/spot_author.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';

/// Strumenti del proprietario del canale. Le implementazioni lanciano un
/// `Failure`; chi non è proprietario riceve `PermissionFailure`.
abstract interface class ModerationRepository {
  /// L'utente loggato è il proprietario del canale.
  Future<bool> isChannelOwner(String channelId);

  /// L'autore di uno spot del canale. Lancia `NotFoundFailure` se lo spot non
  /// esiste.
  Future<SpotAuthor> getSpotAuthor(String spotId);

  /// Cambia lo stato di uno spot. Lancia `NotFoundFailure` se lo spot non
  /// esiste, è già rimosso o ha già quello stato.
  Future<void> setSpotStatus(String spotId, ModerationStatus status);

  /// Nasconde o ripristina un commento. Lancia `NotFoundFailure` se il
  /// commento non esiste o ha già quello stato.
  Future<void> setCommentHidden(String commentId, {required bool hidden});

  /// Pagina degli spot nascosti del canale, dal più recente.
  Future<List<Spot>> getHiddenSpots({
    required String channelId,
    required int offset,
    required int limit,
  });
}
