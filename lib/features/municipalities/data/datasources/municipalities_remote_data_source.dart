import 'package:spotted/features/municipalities/data/models/municipality_dto.dart';
import 'package:spotted/features/municipalities/data/models/province_dto.dart';
import 'package:spotted/features/municipalities/domain/entities/municipality.dart';
import 'package:spotted/features/municipalities/domain/entities/province.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// L'elenco dei comuni sta nel database (`municipalities`, dati ISTAT) e si
/// interroga con RPC, che non distinguono maiuscole e accenti.
class MunicipalitiesRemoteDataSource {
  const MunicipalitiesRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Municipality>> search(String query, {required int limit}) async {
    final rows = await _client.rpc<List<dynamic>>(
      'search_municipalities',
      params: {'p_query': query, 'p_limit': limit},
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => MunicipalityDto.fromJson(row).toEntity())
        .toList();
  }

  Future<List<String>> getRegions() async {
    final rows = await _client.rpc<List<dynamic>>('municipality_regions');
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => row['region_name'] as String)
        .toList();
  }

  Future<List<Province>> getProvinces({String? region}) async {
    final rows = await _client.rpc<List<dynamic>>(
      'municipality_provinces',
      params: {'p_region': region},
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => ProvinceDto.fromJson(row).toEntity())
        .toList();
  }
}
