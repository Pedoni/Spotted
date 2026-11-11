import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/reports/data/models/channel_report_dto.dart';
import 'package:spotted/features/reports/domain/entities/channel_report.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';
import 'package:spotted/features/reports/domain/entities/report_resolution.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `reports` è chiusa ai client (nessuno vede chi segnala): tutto passa da
/// RPC. Il database risponde `23505` se il contenuto è già stato segnalato
/// dall'utente e `42501` se è suo o se chi chiama non è il proprietario.
class ReportsRemoteDataSource {
  const ReportsRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// L'RPC restituisce `false` se lo spot non esiste o non è pubblicato.
  Future<void> reportSpot({
    required String spotId,
    required ReportReason reason,
    String? details,
  }) async {
    final created = await _client.rpc<bool>(
      'report_spot',
      params: {
        'p_spot_id': spotId,
        'p_reason': reason.name,
        'p_details': details,
      },
    );
    if (!created) throw const NotFoundFailure();
  }

  /// L'RPC restituisce `false` se il commento non esiste o non è visibile.
  Future<void> reportComment({
    required String commentId,
    required ReportReason reason,
    String? details,
  }) async {
    final created = await _client.rpc<bool>(
      'report_comment',
      params: {
        'p_comment_id': commentId,
        'p_reason': reason.name,
        'p_details': details,
      },
    );
    if (!created) throw const NotFoundFailure();
  }

  Future<List<ChannelReport>> getChannelReports({
    required String channelId,
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'channel_reports_page',
      params: {
        'p_channel_id': channelId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => ChannelReportDto.fromJson(row).toEntity())
        .toList();
  }

  /// L'RPC restituisce `false` se la segnalazione non esiste o è già chiusa.
  Future<void> resolveReport(
    String reportId,
    ReportResolution resolution,
  ) async {
    final changed = await _client.rpc<bool>(
      'resolve_report',
      params: {'p_report_id': reportId, 'p_status': resolution.name},
    );
    if (!changed) throw const NotFoundFailure();
  }
}
