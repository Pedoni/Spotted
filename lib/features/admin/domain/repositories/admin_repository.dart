import 'package:spotted/features/admin/domain/entities/admin_action.dart';
import 'package:spotted/features/admin/domain/entities/admin_report.dart';

/// Strumenti dell'admin. Le implementazioni lanciano un `Failure`; chi non è
/// admin riceve `PermissionFailure` (tranne da [isAdmin], che risponde
/// `false`).
abstract interface class AdminRepository {
  /// L'utente loggato è admin (mostra la voce del pannello nel Profilo).
  Future<bool> isAdmin();

  /// Pagina delle segnalazioni aperte di tutti i canali, dalla più recente.
  Future<List<AdminReport>> getReports({
    required int offset,
    required int limit,
  });

  /// Agisce su una segnalazione. Lancia `NotFoundFailure` se non esiste o non è
  /// più aperta.
  Future<void> act(String reportId, AdminAction action);
}
