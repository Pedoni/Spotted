import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/entities/spot_stats.dart';
import 'package:spotted/features/spots/presentation/providers/spots_providers.dart';

part 'spot_interaction.g.dart';

/// Conteggi modificati dall'utente (like, commenti) rispetto a quelli con cui
/// lo spot era stato caricato (`base`).
class SpotStatsOverride extends Equatable {
  const SpotStatsOverride({required this.base, required this.current});

  final SpotStats base;
  final SpotStats current;

  @override
  List<Object?> get props => [base, current];
}

/// Le modifiche locali ai conteggi di uno spot (uno per spot).
///
/// Lo stesso spot compare in più liste (canale, "i miei spot", dettaglio):
/// invece di aggiornarle tutte, ogni schermata mostra `effective`. Se la lista
/// viene ricaricata dal server i conteggi cambiano rispetto a `base` e vince
/// il dato del server.
///
/// Resta vivo (`keepAlive`) per non perdere le modifiche quando lo spot esce
/// dallo schermo; si azzera al cambio di utente.
@Riverpod(keepAlive: true)
class SpotInteraction extends _$SpotInteraction {
  bool _busy = false;

  @override
  SpotStatsOverride? build(String spotId) {
    // Un altro utente non deve vedere i "mi piace" del precedente.
    ref.watch(authStateProvider);
    return null;
  }

  /// I conteggi da mostrare per [spot].
  static SpotStats effective(Spot spot, SpotStatsOverride? override) {
    return (override != null && override.base == spot.stats)
        ? override.current
        : spot.stats;
  }

  /// Mette o toglie il like. Aggiorna subito i conteggi (così la UI risponde
  /// senza attese); se la richiesta fallisce torna ai valori precedenti e
  /// rilancia l'errore.
  Future<void> toggleLike(Spot spot) async {
    if (_busy) return;
    final current = effective(spot, state);
    final next = current.toggledLike();

    _busy = true;
    state = SpotStatsOverride(base: spot.stats, current: next);
    try {
      await ref.read(setSpotLikedUseCaseProvider)(
        spot.id,
        liked: next.likedByMe,
      );
    } on Exception {
      if (ref.mounted) {
        state = SpotStatsOverride(base: spot.stats, current: current);
      }
      rethrow;
    } finally {
      _busy = false;
    }
  }

  /// Aggiorna il numero di commenti dopo averne aggiunto o tolto uno.
  void addComments(Spot spot, int delta) {
    final current = effective(spot, state);
    state = SpotStatsOverride(
      base: spot.stats,
      current: current.withCommentCount(current.commentCount + delta),
    );
  }
}
