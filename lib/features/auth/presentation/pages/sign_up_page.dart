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

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
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
                decoration: InputDecoration(
                  labelText: l10n.usernameLabel,
                ),
                validator: (v) => AuthValidators.isValidUsername(v ?? '')
                    ? null
                    : l10n.validationUsername,
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
