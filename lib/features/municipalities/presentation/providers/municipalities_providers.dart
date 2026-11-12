import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/municipalities/data/datasources/municipalities_remote_data_source.dart';
import 'package:spotted/features/municipalities/data/repositories/municipalities_repository_impl.dart';
import 'package:spotted/features/municipalities/domain/entities/province.dart';
import 'package:spotted/features/municipalities/domain/repositories/municipalities_repository.dart';
import 'package:spotted/features/municipalities/domain/usecases/get_provinces.dart';
import 'package:spotted/features/municipalities/domain/usecases/get_regions.dart';
import 'package:spotted/features/municipalities/domain/usecases/search_municipalities.dart';

part 'municipalities_providers.g.dart';

@Riverpod(keepAlive: true)
MunicipalitiesRepository municipalitiesRepository(Ref ref) {
  return MunicipalitiesRepositoryImpl(
    MunicipalitiesRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
SearchMunicipalities searchMunicipalitiesUseCase(Ref ref) {
  return SearchMunicipalities(ref.watch(municipalitiesRepositoryProvider));
}

@riverpod
GetRegions getRegionsUseCase(Ref ref) {
  return GetRegions(ref.watch(municipalitiesRepositoryProvider));
}

@riverpod
GetProvinces getProvincesUseCase(Ref ref) {
  return GetProvinces(ref.watch(municipalitiesRepositoryProvider));
}

/// Le regioni (per i filtri): non cambiano durante la sessione.
@Riverpod(keepAlive: true)
Future<List<String>> regions(Ref ref) {
  return ref.watch(getRegionsUseCaseProvider)();
}

/// Le province di una regione, o tutte se [region] è `null`.
@riverpod
Future<List<Province>> provinces(Ref ref, String? region) {
  return ref.watch(getProvincesUseCaseProvider)(region: region);
}
