import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/admin/data/models/admin_report_dto.dart';
import 'package:spotted/features/admin/domain/entities/admin_action.dart';
import 'package:spotted/features/admin/domain/entities/admin_report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tutto passa da RPC riservate agli admin: chi non lo è riceve `42501`. Chi è
/// admin lo decide solo il database (`profiles.is_admin`).
class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<bool> isAdmin() async {
    final admin = await _client.rpc<bool>('is_admin');
    return admin;
  }

  Future<List<AdminReport>> getReports({
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'admin_reports_page',
      params: {'p_limit': limit, 'p_offset': offset},
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => AdminReportDto.fromJson(row).toEntity())
        .toList();
  }

  /// L'RPC restituisce `false` se la segnalazione non esiste o non è aperta.
  Future<void> act(String reportId, AdminAction action) async {
    final done = await _client.rpc<bool>(
      'admin_act_on_report',
      params: {'p_report_id': reportId, 'p_action': action.name},
    );
    if (!done) throw const NotFoundFailure();
  }
}
