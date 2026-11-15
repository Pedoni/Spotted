import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/auth/domain/auth_validators.dart';
import 'package:spotted/features/auth/presentation/providers/auth_controllers.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:spotted/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:spotted/features/auth/presentation/widgets/password_field.dart';
import 'package:spotted/l10n/app_localizations.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Quanto si aspetta, dopo l'ultima lettera, prima di chiedere se lo
  /// username è libero.
  static const _usernameDelay = Duration(milliseconds: 500);

  Timer? _usernameTimer;

  /// Esito del controllo dello username. `taken` vale solo per [_checkedName]:
  /// se il testo cambia non vale più.
  _UsernameStatus _usernameStatus = _UsernameStatus.idle;
  String _checkedName = '';

  @override
  void dispose() {
    _usernameTimer?.cancel();
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameTimer?.cancel();
    final name = value.trim().toLowerCase();
    if (!AuthValidators.isValidUsername(name)) {
      setState(() => _usernameStatus = _UsernameStatus.idle);
      return;
    }
    setState(() => _usernameStatus = _UsernameStatus.checking);
    _usernameTimer = Timer(
      _usernameDelay,
      () => unawaited(_checkUsername(name)),
    );
  }

  Future<void> _checkUsername(String name) async {
    _UsernameStatus result;
    try {
      final free = await ref.read(checkUsernameAvailableUseCaseProvider)(name);
      result = free ? _UsernameStatus.available : _UsernameStatus.taken;
    } on Exception {
      // Senza rete non si dice niente: alla registrazione si ricontrolla.
      result = _UsernameStatus.idle;
    }
    // Una risposta in ritardo non vale se nel frattempo il testo è cambiato.
    if (!mounted || _username.text.trim().toLowerCase() != name) return;
    setState(() {
      _usernameStatus = result;
      _checkedName = name;
    });
  }

  bool get _usernameTaken =>
      _usernameStatus == _UsernameStatus.taken &&
      _checkedName == _username.text.trim().toLowerCase();

  void _submit() {
    // Se il controllo dello username è ancora in attesa lo fa il signup
    // stesso, subito prima di registrare: due avvisi sarebbero troppi.
    _usernameTimer?.cancel();
    if (_usernameStatus == _UsernameStatus.checking) {
      setState(() => _usernameStatus = _UsernameStatus.idle);
    }
    if (!_formKey.currentState!.validate()) return;
    unawaited(
      ref
          .read(signUpControllerProvider.notifier)
          .submit(
            email: _email.text,
            password: _password.text,
            username: _username.text,
            firstName: _firstName.text,
            lastName: _lastName.text,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(signUpControllerProvider);

    String? validateName(String? v) =>
        AuthValidators.isValidName(v ?? '') ? null : l10n.validationRequired;

    return AuthFormLayout(
      title: l10n.signUpTitle,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                decoration: InputDecoration(
                  labelText: l10n.firstNameLabel,
                ),
                validator: validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
                decoration: InputDecoration(
                  labelText: l10n.lastNameLabel,
                ),
                validator: validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _username,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                onChanged: _onUsernameChanged,
                decoration: InputDecoration(
                  labelText: l10n.usernameLabel,
                  errorText: _usernameTaken ? l10n.errorUsernameTaken : null,
                  helperText: _usernameStatus == _UsernameStatus.available
                      ? l10n.usernameAvailable
                      : null,
                  suffixIcon: switch (_usernameStatus) {
                    _UsernameStatus.checking => const Padding(
                      padding: EdgeInsets.all(14),
                      child: InlineProgress(size: 18),
                    ),
                    _UsernameStatus.available => Icon(
                      Icons.check_circle_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _ => null,
                  },
                ),
                validator: (v) {
                  if (!AuthValidators.isValidUsername(v ?? '')) {
                    return l10n.validationUsername;
                  }
                  return _usernameTaken ? l10n.errorUsernameTaken : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                ),
                validator: (v) => AuthValidators.isValidEmail(v ?? '')
                    ? null
                    : l10n.validationEmail,
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                label: l10n.passwordLabel,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: _submit,
                validator: (v) => AuthValidators.isValidPassword(v ?? '')
                    ? null
                    : l10n.validationPassword(AuthValidators.minPasswordLength),
              ),
              if (state.hasError) ...[
                const SizedBox(height: 16),
                AuthErrorBanner(message: failureMessage(l10n, state.error!)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const InlineProgress()
                    : Text(l10n.signUpButton),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(l10n.goToLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A che punto è il controllo dello username mentre si scrive.
enum _UsernameStatus { idle, checking, available, taken }
