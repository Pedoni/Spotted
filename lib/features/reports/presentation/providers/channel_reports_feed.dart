import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/features/reports/domain/entities/channel_report.dart';
import 'package:spotted/features/reports/domain/entities/report_resolution.dart';
import 'package:spotted/features/reports/presentation/providers/reports_providers.dart';
import 'package:spotted/features/spots/presentation/providers/channel_spots_feed.dart';

part 'channel_reports_feed.g.dart';

/// Segnalazioni aperte di un canale, dalla più recente (solo per il
/// proprietario). Un'istanza per canale.
@riverpod
class ChannelReportsFeed extends _$ChannelReportsFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<ChannelReport>> build(String channelId) async {
    _generation++;
    final items = await ref.read(getChannelReportsUseCaseProvider)(
      channelId: channelId,
      offset: 0,
      limit: spotsPageSize,
    );
    return PagedList(items: items, hasMore: items.length == spotsPageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final more = await ref.read(getChannelReportsUseCaseProvider)(
        channelId: channelId,
        offset: current.items.length,
        limit: spotsPageSize,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        PagedList(
          items: [...current.items, ...more],
          hasMore: more.length == spotsPageSize,
        ),
      );
    } on Exception {
      if (ref.mounted && generation == _generation) {
        state = AsyncData(
          current.copyWith(isLoadingMore: false, loadMoreFailed: true),
        );
      }
    }
  }

  /// Chiude una segnalazione e la toglie dalla lista. Se fallisce rilancia
  /// l'errore e la lista non cambia.
  Future<void> resolve(String reportId, ReportResolution resolution) async {
    await ref.read(resolveReportUseCaseProvider)(reportId, resolution);
    final current = state.value;
    if (!ref.mounted || current == null) return;
    state = AsyncData(
      current.copyWith(
        items: [
          for (final report in current.items)
            if (report.id != reportId) report,
        ],
      ),
    );
  }
}
