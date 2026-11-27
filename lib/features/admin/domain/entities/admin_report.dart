import 'package:equatable/equatable.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';

/// Una segnalazione aperta, come la vede l'admin: di qualunque canale, con il
/// testo segnalato. Mai chi ha segnalato né l'autore del contenuto.
class AdminReport extends Equatable {
  const AdminReport({
    required this.id,
    required this.kind,
    required this.spotId,
    required this.spotTitle,
    required this.content,
    required this.reason,
    required this.createdAt,
    required this.channelName,
    required this.channelSlug,
    this.details,
    this.contentHidden = false,
    this.reportCount = 1,
  });

  final String id;
  final ReportKind kind;

  /// Lo spot segnalato, o quello sotto cui sta il commento segnalato.
  final String spotId;
  final String spotTitle;

  /// Il testo segnalato: dello spot o del commento.
  final String content;
  final ReportReason reason;
  final String? details;
  final DateTime createdAt;
  final String channelName;
  final String channelSlug;

  /// Il contenuto è già nascosto (dal proprietario).
  final bool contentHidden;

  /// Quante segnalazioni aperte ha lo stesso contenuto (compresa questa).
  final int reportCount;

  @override
  List<Object?> get props => [
    id,
    kind,
    spotId,
    spotTitle,
    content,
    reason,
    details,
    createdAt,
    channelName,
    channelSlug,
    contentHidden,
    reportCount,
  ];
}
