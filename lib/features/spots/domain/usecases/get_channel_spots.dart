import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/domain/repositories/spots_repository.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';

class GetChannelSpots {
  const GetChannelSpots(this._repository);

  final SpotsRepository _repository;

  /// Gli spot di un canale; con [query] solo quelli che contengono il testo.
  /// Un testo troppo corto non cerca niente (e non fa richieste): la ricerca
  /// parte da [SpotValidators.minSearchLength] lettere.
  Future<List<Spot>> call({
    required String channelId,
    required int offset,
    required int limit,
    String? query,
  }) {
    final text = SpotValidators.searchText(query);
    if (text != null && !SpotValidators.isSearchLongEnough(text)) {
      return Future.value(const []);
    }
    return _repository.getChannelSpots(
      channelId: channelId,
      offset: offset,
      limit: limit,
      query: text,
    );
  }
}
