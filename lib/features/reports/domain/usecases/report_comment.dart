import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';
import 'package:spotted/features/reports/domain/report_validators.dart';
import 'package:spotted/features/reports/domain/repositories/reports_repository.dart';

class ReportComment {
  const ReportComment(this._repository);

  final ReportsRepository _repository;

  /// Valida i dettagli (togliendo gli spazi ai bordi; vuoti diventano
  /// assenti) e segnala.
  Future<void> call({
    required String commentId,
    required ReportReason reason,
    String? details,
  }) async {
    if (!ReportValidators.isDetailsValid(details)) {
      throw const ValidationFailure();
    }
    final trimmed = details?.trim();
    await _repository.reportComment(
      commentId: commentId,
      reason: reason,
      details: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
  }
}
