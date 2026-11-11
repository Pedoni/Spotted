import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/router/app_routes.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/auth/domain/auth_validators.dart';
import 'package:spotted/features/auth/presentation/providers/auth_controllers.dart';
import 'package:spotted/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:spotted/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:spotted/features/auth/presentation/widgets/password_field.dart';
import 'package:spotted/l10n/app_localizations.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    unawaited(
      ref
          .read(signInControllerProvider.notifier)
          .submit(email: _email.text, password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(signInControllerProvider);

    return AuthFormLayout(
      tall: true,
      title: l10n.loginTitle,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                onSubmitted: _submit,
                validator: (v) =>
                    (v ?? '').isEmpty ? l10n.validationRequired : null,
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
                    : Text(l10n.loginButton),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(AppRoutes.signUp),
                child: Text(l10n.goToSignUp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
