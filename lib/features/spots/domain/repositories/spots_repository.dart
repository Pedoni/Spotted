import 'package:spotted/features/spots/domain/entities/my_spot.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';

/// Contratto degli spot. Le implementazioni lanciano un `Failure`.
abstract interface class SpotsRepository {
  /// Pagina di spot di un canale, dal più recente.
  Future<List<Spot>> getChannelSpots({
    required String channelId,
    required int offset,
    required int limit,
  });

  /// Pagina degli spot scritti dall'utente loggato, dal più recente.
  Future<List<MySpot>> getMySpots({required int offset, required int limit});

  /// Pubblica uno spot nel canale a nome (anonimo) dell'utente loggato.
  Future<Spot> createSpot({
    required String channelId,
    required String title,
    required String content,
  });

  /// Cancella uno spot dell'utente. Lancia `NotFoundFailure` se non esiste o
  /// non è suo.
  Future<void> deleteSpot(String spotId);
}
