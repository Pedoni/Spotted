import 'package:spotted/features/municipalities/domain/entities/municipality.dart';
import 'package:spotted/features/municipalities/domain/repositories/municipalities_repository.dart';

class SearchMunicipalities {
  const SearchMunicipalities(this._repository);

  /// Sotto questa lunghezza non si cerca: una sola lettera darebbe centinaia
  /// di comuni.
  static const minQueryLength = 2;
  static const defaultLimit = 8;

  final MunicipalitiesRepository _repository;

  /// Cerca i comuni; con un testo troppo corto non fa nessuna richiesta.
  Future<List<Municipality>> call(String query, {int limit = defaultLimit}) {
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) return Future.value(const []);
    return _repository.search(trimmed, limit: limit);
  }
}
