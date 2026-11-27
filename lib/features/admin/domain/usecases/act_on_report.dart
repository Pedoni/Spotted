import 'package:spotted/features/admin/domain/entities/admin_action.dart';
import 'package:spotted/features/admin/domain/repositories/admin_repository.dart';

class ActOnReport {
  const ActOnReport(this._repository);

  final AdminRepository _repository;

  Future<void> call(String reportId, AdminAction action) =>
      _repository.act(reportId, action);
}
