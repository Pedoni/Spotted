import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/l10n/app_localizations_it.dart';

void main() {
  final l10n = AppLocalizationsIt();

  test('ogni tipo di errore ha il suo messaggio', () {
    expect(
      failureMessage(l10n, const NetworkFailure()),
      'Problema di connessione. Riprova.',
    );
    expect(
      failureMessage(l10n, const ConflictFailure()),
      l10n.errorConflict,
    );
    expect(
      failureMessage(l10n, const NotFoundFailure()),
      l10n.errorNotFound,
    );
    expect(
      failureMessage(l10n, const PermissionFailure()),
      'Non hai i permessi per eseguire questa azione',
    );
    expect(
      failureMessage(l10n, const SessionExpiredFailure()),
      'Sessione scaduta. Accedi di nuovo.',
    );
    expect(
      failureMessage(l10n, const ValidationFailure()),
      l10n.errorInvalidInput,
    );
  });

  test('i motivi di AuthFailure hanno messaggi distinti', () {
    final messages = {
      for (final reason in AuthFailureReason.values)
        reason: failureMessage(l10n, AuthFailure(reason)),
    };
    expect(
      messages[AuthFailureReason.invalidCredentials],
      l10n.errorInvalidCredentials,
    );
    expect(messages[AuthFailureReason.emailTaken], l10n.errorEmailTaken);
    expect(messages[AuthFailureReason.usernameTaken], l10n.errorUsernameTaken);
    expect(messages[AuthFailureReason.weakPassword], l10n.errorWeakPassword);
  });

  test('errore sconosciuto o non-Failure: messaggio generico', () {
    expect(failureMessage(l10n, const UnknownFailure('x')), l10n.errorGeneric);
    expect(failureMessage(l10n, StateError('x')), l10n.errorGeneric);
  });
}
