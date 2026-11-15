import 'package:spotted/features/municipalities/domain/entities/province.dart';
import 'package:spotted/features/municipalities/domain/repositories/municipalities_repository.dart';

class GetProvinces {
  const GetProvinces(this._repository);

  final MunicipalitiesRepository _repository;

  Future<List<Province>> call({String? region}) =>
      _repository.getProvinces(region: region);
}
