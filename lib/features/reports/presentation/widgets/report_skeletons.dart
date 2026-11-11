import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/reports/domain/entities/channel_report.dart';
import 'package:spotted/features/reports/domain/entities/report_kind.dart';
import 'package:spotted/features/reports/domain/entities/report_reason.dart';
import 'package:spotted/features/reports/presentation/widgets/report_card.dart';

/// Scheletro di un elenco di segnalazioni.
class ReportCardsSkeleton extends StatelessWidget {
  const ReportCardsSkeleton({this.count = 3, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            ReportCard(
              report: ChannelReport(
                id: 'skeleton-$i',
                kind: ReportKind.spot,
                spotId: 'skeleton',
                spotTitle: 'Titolo dello spot segnalato',
                content:
                    'Il testo segnalato, su un paio di righe di lunghezza '
                    'media.',
                reason: ReportReason.spam,
                createdAt: DateTime(2026),
              ),
              onOpen: () {},
              onResolve: (_) {},
            ),
        ],
      ),
    );
  }
}
