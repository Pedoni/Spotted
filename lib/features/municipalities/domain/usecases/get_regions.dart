import 'package:spotted/features/municipalities/domain/repositories/municipalities_repository.dart';

class GetRegions {
  const GetRegions(this._repository);

  final MunicipalitiesRepository _repository;

  Future<List<String>> call() => _repository.getRegions();
}
