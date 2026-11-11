import 'package:equatable/equatable.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';

/// Una segnalazione aperta su un contenuto del canale, come la vede il
/// proprietario. Mai chi ha segnalato: le segnalazioni sono anonime.
class ChannelReport extends Equatable {
  const ChannelReport({
    required this.id,
    required this.kind,
    required this.spotId,
    required this.spotTitle,
    required this.content,
    required this.reason,
    required this.createdAt,
    this.details,
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
  ];
}
