import 'package:spotted/features/municipalities/domain/entities/municipality.dart';
import 'package:spotted/features/municipalities/domain/entities/province.dart';

/// Contratto dell'elenco dei comuni. Le implementazioni lanciano un `Failure`.
abstract interface class MunicipalitiesRepository {
  /// I comuni il cui nome contiene [query], prima quelli che iniziano così.
  /// Non distingue maiuscole e accenti.
  Future<List<Municipality>> search(String query, {required int limit});

  /// Le regioni, in ordine alfabetico.
  Future<List<String>> getRegions();

  /// Le province di [region], o tutte se è `null`, in ordine alfabetico.
  Future<List<Province>> getProvinces({String? region});
}
