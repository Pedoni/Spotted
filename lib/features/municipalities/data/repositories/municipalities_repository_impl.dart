import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/municipalities/data/datasources/municipalities_remote_data_source.dart';
import 'package:spotted/features/municipalities/domain/entities/municipality.dart';
import 'package:spotted/features/municipalities/domain/entities/province.dart';
import 'package:spotted/features/municipalities/domain/repositories/municipalities_repository.dart';

class MunicipalitiesRepositoryImpl implements MunicipalitiesRepository {
  const MunicipalitiesRepositoryImpl(this._dataSource);

  final MunicipalitiesRemoteDataSource _dataSource;

  @override
  Future<List<Municipality>> search(String query, {required int limit}) {
    return guardFailures(() => _dataSource.search(query, limit: limit));
  }

  @override
  Future<List<String>> getRegions() {
    return guardFailures(_dataSource.getRegions);
  }

  @override
  Future<List<Province>> getProvinces({String? region}) {
    return guardFailures(() => _dataSource.getProvinces(region: region));
  }
}
