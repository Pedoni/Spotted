import 'dart:async';

import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/admin/domain/entities/admin_action.dart';
import 'package:spotted/features/admin/domain/entities/admin_report.dart';
import 'package:spotted/features/admin/domain/repositories/admin_repository.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';

/// Una segnalazione per l'admin. Con [comment] è su un commento.
AdminReport makeAdminReport(
  int i, {
  bool comment = false,
  String channelName = 'Spotted Pisa',
  ReportReason reason = ReportReason.spam,
  String? details,
  bool hidden = false,
  int count = 1,
}) {
  return AdminReport(
    id: 'r$i',
    kind: comment ? ReportKind.comment : ReportKind.spot,
    spotId: 's$i',
    spotTitle: 'Spot segnalato $i',
    content: comment ? 'Testo commento $i' : 'Testo spot $i',
    reason: reason,
    details: details,
    createdAt: DateTime(2026).subtract(Duration(minutes: i)),
    channelName: channelName,
    channelSlug: 'canale-1',
    contentHidden: hidden,
    reportCount: count,
  );
}

/// Il pannello admin in memoria.
class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({this.admin = false, List<AdminReport>? reports})
    : reports = reports ?? [];

  bool admin;
  List<AdminReport> reports;
  Failure? adminError;
  Failure? listError;
  Failure? actError;

  /// Se è impostato, l'azione aspetta che si completi.
  Completer<void>? actGate;

  /// Se è impostato, il caricamento dell'elenco aspetta che si completi.
  Completer<void>? listGate;

  final listCalls = <({int offset, int limit})>[];
  final actCalls = <({String reportId, AdminAction action})>[];

  @override
  Future<bool> isAdmin() async {
    if (adminError != null) throw adminError!;
    return admin;
  }

  @override
  Future<List<AdminReport>> getReports({
    required int offset,
    required int limit,
  }) async {
    listCalls.add((offset: offset, limit: limit));
    if (listGate != null) await listGate!.future;
    if (listError != null) throw listError!;
    return reports.skip(offset).take(limit).toList();
  }

  @override
  Future<void> act(String reportId, AdminAction action) async {
    actCalls.add((reportId: reportId, action: action));
    if (actGate != null) await actGate!.future;
    if (actError != null) throw actError!;
    reports = reports.where((r) => r.id != reportId).toList();
  }
}
