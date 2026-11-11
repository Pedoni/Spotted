import 'package:spotted/features/reports/domain/entities/report_resolution.dart';
import 'package:spotted/features/reports/domain/repositories/reports_repository.dart';

class ResolveReport {
  const ResolveReport(this._repository);

  final ReportsRepository _repository;

  Future<void> call(String reportId, ReportResolution resolution) =>
      _repository.resolveReport(reportId, resolution);
}
