import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:spotted/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:spotted/features/reports/domain/repositories/reports_repository.dart';
import 'package:spotted/features/reports/domain/usecases/get_channel_reports.dart';
import 'package:spotted/features/reports/domain/usecases/report_comment.dart';
import 'package:spotted/features/reports/domain/usecases/report_spot.dart';
import 'package:spotted/features/reports/domain/usecases/resolve_report.dart';

part 'reports_providers.g.dart';

@Riverpod(keepAlive: true)
ReportsRepository reportsRepository(Ref ref) {
  return ReportsRepositoryImpl(
    ReportsRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
ReportSpot reportSpotUseCase(Ref ref) {
  return ReportSpot(ref.watch(reportsRepositoryProvider));
}

@riverpod
ReportComment reportCommentUseCase(Ref ref) {
  return ReportComment(ref.watch(reportsRepositoryProvider));
}

@riverpod
GetChannelReports getChannelReportsUseCase(Ref ref) {
  return GetChannelReports(ref.watch(reportsRepositoryProvider));
}

@riverpod
ResolveReport resolveReportUseCase(Ref ref) {
  return ResolveReport(ref.watch(reportsRepositoryProvider));
}
