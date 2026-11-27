import 'package:spotted/features/admin/domain/entities/admin_report.dart';
import 'package:spotted/features/admin/domain/repositories/admin_repository.dart';

class GetAdminReports {
  const GetAdminReports(this._repository);

  final AdminRepository _repository;

  Future<List<AdminReport>> call({
    required int offset,
    required int limit,
  }) => _repository.getReports(offset: offset, limit: limit);
}
