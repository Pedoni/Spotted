import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_with_channel.dart';

/// Contratto degli spot. Le implementazioni lanciano un `Failure`.
abstract interface class SpotsRepository {
  /// Pagina di spot di un canale, dal più recente. Con [query] restano solo
  /// gli spot il cui titolo o testo contiene quel testo (ovunque, senza
  /// distinguere maiuscole e accenti).
  Future<List<Spot>> getChannelSpots({
    required String channelId,
    required int offset,
    required int limit,
    String? query,
  });

  /// Un singolo spot. Lancia `NotFoundFailure` se non esiste.
  Future<Spot> getSpot(String spotId);

  /// Pagina degli spot scritti dall'utente loggato, dal più recente.
  Future<List<SpotWithChannel>> getMySpots({
    required int offset,
    required int limit,
  });

  /// Gli spot pubblicati nei canali seguiti, dal più recente.
  Future<List<SpotWithChannel>> getFollowedSpots({
    required int offset,
    required int limit,
  });

  /// Pubblica uno spot nel canale a nome (anonimo) dell'utente loggato.
  Future<Spot> createSpot({
    required String channelId,
    required String title,
    required String content,
  });

  /// Cancella uno spot dell'utente. Lancia `NotFoundFailure` se non esiste o
  /// non è suo.
  Future<void> deleteSpot(String spotId);

  /// Mette o toglie il "mi piace" dell'utente loggato.
  Future<void> setSpotLiked(String spotId, {required bool liked});
}
