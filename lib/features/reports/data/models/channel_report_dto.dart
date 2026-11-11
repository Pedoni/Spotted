import 'package:json_annotation/json_annotation.dart';
import 'package:spotted/features/reports/domain/entities/channel_report.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';

part 'channel_report_dto.g.dart';

/// Riga dell'RPC `channel_reports_page`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class ChannelReportDto {
  const ChannelReportDto({
    required this.id,
    required this.kind,
    required this.spotId,
    required this.spotTitle,
    required this.content,
    required this.reason,
    required this.createdAt,
    this.details,
  });

  factory ChannelReportDto.fromJson(Map<String, dynamic> json) =>
      _$ChannelReportDtoFromJson(json);

  final String id;
  final ReportKind kind;
  final String spotId;
  final String spotTitle;
  final String content;
  final ReportReason reason;
  final String? details;
  final DateTime createdAt;

  ChannelReport toEntity() => ChannelReport(
    id: id,
    kind: kind,
    spotId: spotId,
    spotTitle: spotTitle,
    content: content,
    reason: reason,
    details: details,
    createdAt: createdAt,
  );
}
