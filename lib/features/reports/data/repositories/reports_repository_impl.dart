import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:spotted/features/reports/domain/entities/channel_report.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';
import 'package:spotted/features/reports/domain/entities/report_resolution.dart';
import 'package:spotted/features/reports/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl(this._dataSource);

  final ReportsRemoteDataSource _dataSource;

  @override
  Future<void> reportSpot({
    required String spotId,
    required ReportReason reason,
    String? details,
  }) {
    return guardFailures(
      () => _dataSource.reportSpot(
        spotId: spotId,
        reason: reason,
        details: details,
      ),
    );
  }

  @override
  Future<void> reportComment({
    required String commentId,
    required ReportReason reason,
    String? details,
  }) {
    return guardFailures(
      () => _dataSource.reportComment(
        commentId: commentId,
        reason: reason,
        details: details,
      ),
    );
  }

  @override
  Future<List<ChannelReport>> getChannelReports({
    required String channelId,
    required int offset,
    required int limit,
  }) {
    return guardFailures(
      () => _dataSource.getChannelReports(
        channelId: channelId,
        offset: offset,
        limit: limit,
      ),
    );
  }

  @override
  Future<void> resolveReport(String reportId, ReportResolution resolution) {
    return guardFailures(
      () => _dataSource.resolveReport(reportId, resolution),
    );
  }
}
