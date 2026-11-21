import 'package:spotted/features/moderation/domain/entities/blocked_user.dart';
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

  /// Pagina degli spot in attesa di approvazione, dal più vecchio.
  Future<List<Spot>> getPendingSpots({
    required String channelId,
    required int offset,
    required int limit,
  });

  /// Quanti spot del canale aspettano l'approvazione.
  Future<int> getPendingSpotsCount(String channelId);

  /// Pubblica uno spot in attesa con i [tags] scelti (da 1 a 3, validi per il
  /// canale). Lancia `NotFoundFailure` se lo spot non esiste o non è in
  /// attesa, `ValidationFailure` se i tag non valgono.
  Future<void> approveSpot(String spotId, List<String> tags);

  /// Rifiuta uno spot in attesa. Lancia `NotFoundFailure` se lo spot non
  /// esiste o non è in attesa.
  Future<void> rejectSpot(String spotId);

  /// Blocca o sblocca l'utente di una chat con il canale (solo il
  /// proprietario). Un utente bloccato non può più scrivere al canale né
  /// inviargli spot. Lancia `NotFoundFailure` se la chat non esiste o l'utente
  /// era già in quello stato.
  Future<void> setChatUserBlocked(String chatId, {required bool blocked});

  /// L'utente di questa chat con il canale è bloccato (solo per il
  /// proprietario; per gli altri è sempre `false`).
  Future<bool> isChatUserBlocked(String chatId);

  /// Pagina degli utenti bloccati dal canale, dal più recente.
  Future<List<BlockedUser>> getBlockedUsers({
    required String channelId,
    required int offset,
    required int limit,
  });

  /// Toglie un blocco. Lancia `NotFoundFailure` se non esiste.
  Future<void> unblockChannelUser(String blockId);

  /// Pagina degli spot nascosti del canale, dal più recente.
  Future<List<Spot>> getHiddenSpots({
    required String channelId,
    required int offset,
    required int limit,
  });
}
