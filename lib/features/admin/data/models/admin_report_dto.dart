import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/admin/domain/entities/admin_report.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';

part 'admin_report_dto.g.dart';

/// Riga dell'RPC `admin_reports_page`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class AdminReportDto {
  const AdminReportDto({
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
    this.contentStatus,
    this.reportCount = 1,
  });

  factory AdminReportDto.fromJson(Map<String, dynamic> json) =>
      _$AdminReportDtoFromJson(json);

  final String id;
  final ReportKind kind;
  final String spotId;
  final String spotTitle;
  final String content;
  final ReportReason reason;
  final String? details;
  final DateTime createdAt;
  final String channelName;
  final String channelSlug;

  /// Lo stato del contenuto segnalato (`published` o `hidden`).
  final String? contentStatus;

  @JsonKey(defaultValue: 1)
  final int reportCount;

  AdminReport toEntity() => AdminReport(
    id: id,
    kind: kind,
    spotId: spotId,
    spotTitle: spotTitle,
    content: content,
    reason: reason,
    details: details,
    createdAt: createdAt,
    channelName: channelName,
    channelSlug: channelSlug,
    contentHidden: contentStatus == 'hidden',
    reportCount: reportCount,
  );
}
