import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spotted/core/pagination/paged_list.dart';
import 'package:spotted/core/supabase/supabase_providers.dart';
import 'package:spotted/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:spotted/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:spotted/features/admin/domain/entities/admin_action.dart';
import 'package:spotted/features/admin/domain/entities/admin_report.dart';
import 'package:spotted/features/admin/domain/repositories/admin_repository.dart';
import 'package:spotted/features/admin/domain/usecases/act_on_report.dart';
import 'package:spotted/features/admin/domain/usecases/get_admin_reports.dart';
import 'package:spotted/features/admin/domain/usecases/is_admin.dart';

part 'admin_providers.g.dart';

const adminReportsPageSize = 20;

@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) {
  return AdminRepositoryImpl(
    AdminRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
}

@riverpod
IsAdmin isAdminUseCase(Ref ref) {
  return IsAdmin(ref.watch(adminRepositoryProvider));
}

@riverpod
GetAdminReports getAdminReportsUseCase(Ref ref) {
  return GetAdminReports(ref.watch(adminRepositoryProvider));
}

@riverpod
ActOnReport actOnReportUseCase(Ref ref) {
  return ActOnReport(ref.watch(adminRepositoryProvider));
}

/// L'utente loggato è admin (mostra il pannello nel Profilo). Se la richiesta
/// fallisce il pannello resta nascosto.
@riverpod
Future<bool> isAdmin(Ref ref) {
  return ref.watch(isAdminUseCaseProvider)();
}

/// Le segnalazioni aperte di tutti i canali, dalla più recente (solo admin).
@riverpod
class AdminReportsFeed extends _$AdminReportsFeed {
  /// Vedi `ChannelSpotsFeed._generation`.
  int _generation = 0;

  @override
  Future<PagedList<AdminReport>> build() async {
    _generation++;
    final items = await ref.read(getAdminReportsUseCaseProvider)(
      offset: 0,
      limit: adminReportsPageSize,
    );
    return PagedList(
      items: items,
      hasMore: items.length == adminReportsPageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final more = await ref.read(getAdminReportsUseCaseProvider)(
        offset: current.items.length,
        limit: adminReportsPageSize,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        PagedList(
          items: [...current.items, ...more],
          hasMore: more.length == adminReportsPageSize,
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
}

/// Agisce su una segnalazione e ricarica la coda. Resta vivo (`keepAlive`)
/// come `SpotModeration`: nessuno lo ascolta e, se si distruggesse a metà
/// operazione, la coda non si aggiornerebbe.
@Riverpod(keepAlive: true)
class AdminActions extends _$AdminActions {
  @override
  void build() {}

  /// Se fallisce rilancia l'errore e non cambia niente.
  Future<void> act(AdminReport report, AdminAction action) async {
    await ref.read(actOnReportUseCaseProvider)(report.id, action);
    if (!ref.mounted) return;
    ref.invalidate(adminReportsFeedProvider);
  }
}
