import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:spotted/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';
import 'package:spotted/features/reports/domain/entities/report_resolution.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabase supabase;
  late ReportsRemoteDataSource dataSource;

  Map<String, dynamic> sentBody() =>
      jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;

  void respondWith(Object body, {int status = 200}) {
    supabase = MockSupabase((_) async => jsonResponse(body, status: status));
    dataSource = ReportsRemoteDataSource(supabase.client);
  }

  group('reportSpot', () {
    test("chiama l'RPC report_spot con motivo e dettagli", () async {
      respondWith(true);

      await dataSource.reportSpot(
        spotId: 's1',
        reason: ReportReason.hate,
        details: 'Insulti',
      );

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/report_spot');
      expect(sentBody(), {
        'p_spot_id': 's1',
        'p_reason': 'hate',
        'p_details': 'Insulti',
      });
    });

    test('senza dettagli invia null', () async {
      respondWith(true);

      await dataSource.reportSpot(spotId: 's1', reason: ReportReason.spam);

      expect(sentBody()['p_details'], isNull);
    });

    test('spot inesistente o non visibile (false): NotFoundFailure', () async {
      respondWith(false);

      await expectLater(
        dataSource.reportSpot(spotId: 's1', reason: ReportReason.spam),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('reportComment', () {
    test("chiama l'RPC report_comment", () async {
      respondWith(true);

      await dataSource.reportComment(
        commentId: 'k1',
        reason: ReportReason.offensive,
      );

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/report_comment');
      expect(sentBody(), {
        'p_comment_id': 'k1',
        'p_reason': 'offensive',
        'p_details': null,
      });
    });

    test('commento inesistente (false): NotFoundFailure', () async {
      respondWith(false);

      await expectLater(
        dataSource.reportComment(commentId: 'k1', reason: ReportReason.other),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('getChannelReports', () {
    test("chiama l'RPC channel_reports_page con paginazione", () async {
      respondWith(<Object>[]);

      await dataSource.getChannelReports(
        channelId: 'c1',
        offset: 20,
        limit: 20,
      );

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/channel_reports_page',
      );
      expect(sentBody(), {
        'p_channel_id': 'c1',
        'p_limit': 20,
        'p_offset': 20,
      });
    });

    test('legge le segnalazioni di spot e commenti', () async {
      respondWith([
        reportRow('1', details: 'Pubblicità'),
        reportRow('2', kind: 'comment', reason: 'hate'),
      ]);

      final reports = await dataSource.getChannelReports(
        channelId: 'c1',
        offset: 0,
        limit: 20,
      );

      expect(reports, hasLength(2));
      expect(reports[0].kind, ReportKind.spot);
      expect(reports[0].reason, ReportReason.spam);
      expect(reports[0].details, 'Pubblicità');
      expect(reports[0].spotId, 's1');
      expect(reports[0].createdAt, DateTime.utc(2026, 1, 1, 10));
      expect(reports[1].kind, ReportKind.comment);
      expect(reports[1].reason, ReportReason.hate);
      expect(reports[1].details, isNull);
    });
  });

  group('resolveReport', () {
    test("chiama l'RPC resolve_report con lo stato", () async {
      respondWith(true);

      await dataSource.resolveReport('r1', ReportResolution.dismissed);

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/resolve_report');
      expect(sentBody(), {'p_report_id': 'r1', 'p_status': 'dismissed'});
    });

    test('già chiusa o inesistente (false): NotFoundFailure', () async {
      respondWith(false);

      await expectLater(
        dataSource.resolveReport('r1', ReportResolution.resolved),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('errori (repository)', () {
    late ReportsRepositoryImpl repository;

    void respondError(String code) {
      supabase = MockSupabase((_) async => postgrestError(code, 'errore'));
      repository = ReportsRepositoryImpl(
        ReportsRemoteDataSource(supabase.client),
      );
    }

    test('già segnalato (23505): ConflictFailure', () async {
      respondError('23505');

      await expectLater(
        repository.reportSpot(spotId: 's1', reason: ReportReason.spam),
        throwsA(isA<ConflictFailure>()),
      );
      await expectLater(
        repository.reportComment(commentId: 'k1', reason: ReportReason.spam),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('motivo o dettagli non validi (23514): ValidationFailure', () async {
      respondError('23514');

      await expectLater(
        repository.reportSpot(spotId: 's1', reason: ReportReason.spam),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test(
      'contenuto proprio o non proprietario (42501): PermissionFailure',
      () async {
        respondError('42501');

        await expectLater(
          repository.reportSpot(spotId: 's1', reason: ReportReason.spam),
          throwsA(isA<PermissionFailure>()),
        );
        await expectLater(
          repository.getChannelReports(channelId: 'c1', offset: 0, limit: 20),
          throwsA(isA<PermissionFailure>()),
        );
        await expectLater(
          repository.resolveReport('r1', ReportResolution.resolved),
          throwsA(isA<PermissionFailure>()),
        );
      },
    );

    test('risposta con tipi inattesi: UnknownFailure', () async {
      respondWith([
        {'id': 1},
      ]);
      repository = ReportsRepositoryImpl(dataSource);

      await expectLater(
        repository.getChannelReports(channelId: 'c1', offset: 0, limit: 20),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });
}
