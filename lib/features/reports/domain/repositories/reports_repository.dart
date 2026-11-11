import 'package:spotted/features/reports/domain/entities/channel_report.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';
import 'package:spotted/features/reports/domain/entities/report_resolution.dart';

/// Contratto delle segnalazioni. Le implementazioni lanciano un `Failure`:
/// `ConflictFailure` se il contenuto è già stato segnalato dall'utente,
/// `PermissionFailure` se è suo o se chi chiama non è il proprietario.
abstract interface class ReportsRepository {
  /// Segnala uno spot. Lancia `NotFoundFailure` se non esiste o non è visibile.
  Future<void> reportSpot({
    required String spotId,
    required ReportReason reason,
    String? details,
  });

  /// Segnala un commento. Lancia `NotFoundFailure` se non esiste o non è
  /// visibile.
  Future<void> reportComment({
    required String commentId,
    required ReportReason reason,
    String? details,
  });

  /// Pagina delle segnalazioni aperte del canale, dalla più recente
  /// (proprietario).
  Future<List<ChannelReport>> getChannelReports({
    required String channelId,
    required int offset,
    required int limit,
  });

  /// Chiude una segnalazione aperta. Lancia `NotFoundFailure` se non esiste o
  /// è già chiusa.
  Future<void> resolveReport(String reportId, ReportResolution resolution);
}
