import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';
import 'package:spotted/features/reports/domain/report_validators.dart';
import 'package:spotted/features/reports/domain/usecases/report_comment.dart';
import 'package:spotted/features/reports/domain/usecases/report_spot.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  group('ReportValidators', () {
    test('i dettagli sono facoltativi', () {
      expect(ReportValidators.isDetailsValid(null), isTrue);
      expect(ReportValidators.isDetailsValid(''), isTrue);
      expect(ReportValidators.isDetailsValid('   '), isTrue);
    });

    test('al massimo 500 caratteri, senza contare gli spazi ai bordi', () {
      expect(ReportValidators.isDetailsValid('a' * 500), isTrue);
      expect(ReportValidators.isDetailsValid('  ${'a' * 500}  '), isTrue);
      expect(ReportValidators.isDetailsValid('a' * 501), isFalse);
    });
  });

  group('ReportSpot', () {
    test('toglie gli spazi dai dettagli', () async {
      final repository = FakeReportsRepository();

      await ReportSpot(repository)(
        spotId: 's1',
        reason: ReportReason.spam,
        details: '  Pubblicità  ',
      );

      expect(repository.spotCalls.single, (
        spotId: 's1',
        reason: ReportReason.spam,
        details: 'Pubblicità',
      ));
    });

    test('dettagli vuoti diventano assenti', () async {
      final repository = FakeReportsRepository();

      await ReportSpot(repository)(
        spotId: 's1',
        reason: ReportReason.other,
        details: '   ',
      );

      expect(repository.spotCalls.single.details, isNull);
    });

    test(
      'dettagli troppo lunghi: ValidationFailure, nessuna richiesta',
      () async {
        final repository = FakeReportsRepository();

        await expectLater(
          ReportSpot(repository)(
            spotId: 's1',
            reason: ReportReason.spam,
            details: 'a' * 501,
          ),
          throwsA(isA<ValidationFailure>()),
        );
        expect(repository.spotCalls, isEmpty);
      },
    );
  });

  group('ReportComment', () {
    test('toglie gli spazi dai dettagli', () async {
      final repository = FakeReportsRepository();

      await ReportComment(repository)(
        commentId: 'k1',
        reason: ReportReason.hate,
        details: ' Insulti ',
      );

      expect(repository.commentCalls.single, (
        commentId: 'k1',
        reason: ReportReason.hate,
        details: 'Insulti',
      ));
    });

    test(
      'dettagli troppo lunghi: ValidationFailure, nessuna richiesta',
      () async {
        final repository = FakeReportsRepository();

        await expectLater(
          ReportComment(repository)(
            commentId: 'k1',
            reason: ReportReason.spam,
            details: 'a' * 501,
          ),
          throwsA(isA<ValidationFailure>()),
        );
        expect(repository.commentCalls, isEmpty);
      },
    );
  });
}
