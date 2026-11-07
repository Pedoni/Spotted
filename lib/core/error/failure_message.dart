import 'package:spotted/core/error/failure.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Traduce un errore (di solito un [Failure]) in un testo per l'utente.
String failureMessage(AppLocalizations l10n, Object error) {
  return switch (error) {
    AuthFailure(:final reason) => switch (reason) {
      AuthFailureReason.invalidCredentials => l10n.errorInvalidCredentials,
      AuthFailureReason.emailTaken => l10n.errorEmailTaken,
      AuthFailureReason.usernameTaken => l10n.errorUsernameTaken,
      AuthFailureReason.weakPassword => l10n.errorWeakPassword,
      AuthFailureReason.invalidInput => l10n.errorInvalidInput,
      AuthFailureReason.unknown => l10n.errorGeneric,
    },
    ValidationFailure() => l10n.errorInvalidInput,
    ConflictFailure() => l10n.errorConflict,
    NotFoundFailure() => l10n.errorNotFound,
    NetworkFailure() => l10n.errorNetwork,
    _ => l10n.errorGeneric,
  };
}
