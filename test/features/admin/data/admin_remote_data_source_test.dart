import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:spotted/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:spotted/features/admin/domain/entities/admin_action.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabase supabase;
  late AdminRemoteDataSource dataSource;

  void respondWith(Object? body, {int status = 200}) {
    supabase = MockSupabase((_) async => jsonResponse(body, status: status));
    dataSource = AdminRemoteDataSource(supabase.client);
  }

  Map<String, dynamic> row(
    String id, {
    String kind = 'spot',
    String? status = 'published',
    int count = 1,
  }) => {
    'id': id,
    'kind': kind,
    'spot_id': 's1',
    'spot_title': 'Ombrello perso',
    'content': 'Testo',
    'reason': 'hate',
    'details': 'Offende',
    'created_at': '2026-01-01T10:00:00+00:00',
    'channel_name': 'Spotted Pisa',
    'channel_slug': 'spotted-pisa',
    'content_status': status,
    'report_count': count,
  };

  test("isAdmin chiama l'RPC is_admin", () async {
    respondWith(true);

    final admin = await dataSource.isAdmin();

    expect(supabase.lastRequest.url.path, '/rest/v1/rpc/is_admin');
    expect(admin, isTrue);
  });

  test("getReports chiama l'RPC admin_reports_page con paginazione", () async {
    respondWith(<Object>[]);

    await dataSource.getReports(offset: 20, limit: 20);

    expect(supabase.lastRequest.url.path, '/rest/v1/rpc/admin_reports_page');
    expect(jsonDecode(supabase.lastRequest.body), {
      'p_limit': 20,
      'p_offset': 20,
    });
  });

  test('legge canale, motivo, dettagli e numero di segnalazioni', () async {
    respondWith([row('r1', count: 3)]);

    final report = (await dataSource.getReports(offset: 0, limit: 20)).single;

    expect(report.id, 'r1');
    expect(report.kind, ReportKind.spot);
    expect(report.reason, ReportReason.hate);
    expect(report.details, 'Offende');
    expect(report.channelName, 'Spotted Pisa');
    expect(report.channelSlug, 'spotted-pisa');
    expect(report.reportCount, 3);
    expect(report.contentHidden, isFalse);
    expect(report.createdAt, DateTime.utc(2026, 1, 1, 10));
  });

  test('un commento nascosto si legge come già nascosto', () async {
    respondWith([row('r1', kind: 'comment', status: 'hidden')]);

    final report = (await dataSource.getReports(offset: 0, limit: 20)).single;

    expect(report.kind, ReportKind.comment);
    expect(report.contentHidden, isTrue);
  });

  test('senza il numero di segnalazioni vale uno', () async {
    final data = row('r1')..remove('report_count');
    respondWith([data]);

    final report = (await dataSource.getReports(offset: 0, limit: 20)).single;

    expect(report.reportCount, 1);
  });

  group('act', () {
    for (final action in AdminAction.values) {
      test('${action.name}: manda il nome dell azione', () async {
        respondWith(true);

        await dataSource.act('r1', action);

        expect(
          supabase.lastRequest.url.path,
          '/rest/v1/rpc/admin_act_on_report',
        );
        expect(jsonDecode(supabase.lastRequest.body), {
          'p_report_id': 'r1',
          'p_action': action.name,
        });
      });
    }

    test('segnalazione inesistente o già chiusa (false): NotFoundFailure', () {
      respondWith(false);

      expect(
        dataSource.act('r1', AdminAction.dismiss),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('errori (repository)', () {
    late AdminRepositoryImpl repository;

    void respondError(String code) {
      supabase = MockSupabase((_) async => postgrestError(code, 'errore'));
      repository = AdminRepositoryImpl(AdminRemoteDataSource(supabase.client));
    }

    test('chi non è admin (42501): PermissionFailure', () async {
      respondError('42501');

      await expectLater(
        repository.getReports(offset: 0, limit: 20),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repository.act('r1', AdminAction.hide),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('azione non valida (23514): ValidationFailure', () async {
      respondError('23514');

      await expectLater(
        repository.act('r1', AdminAction.remove),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
