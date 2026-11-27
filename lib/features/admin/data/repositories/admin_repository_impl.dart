import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:spotted/features/admin/domain/entities/admin_action.dart';
import 'package:spotted/features/admin/domain/entities/admin_report.dart';
import 'package:spotted/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._dataSource);

  final AdminRemoteDataSource _dataSource;

  @override
  Future<bool> isAdmin() => guardFailures(_dataSource.isAdmin);

  @override
  Future<List<AdminReport>> getReports({
    required int offset,
    required int limit,
  }) {
    return guardFailures(
      () => _dataSource.getReports(offset: offset, limit: limit),
    );
  }

  @override
  Future<void> act(String reportId, AdminAction action) {
    return guardFailures(() => _dataSource.act(reportId, action));
  }
}
