import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/auth/domain/auth_validators.dart';
import 'package:spotted/features/auth/presentation/providers/auth_controllers.dart';
import 'package:spotted/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:spotted/features/auth/presentation/widgets/password_field.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Cambia la password: la attuale (per sicurezza), la nuova e la nuova
/// ripetuta.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final changed = await ref
        .read(changePasswordControllerProvider.notifier)
        .submit(currentPassword: _current.text, newPassword: _new.text);
    if (changed && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(changePasswordControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePassword)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.changePasswordHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    PasswordField(
                      controller: _current,
                      label: l10n.currentPasswordLabel,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v ?? '').isEmpty
                          ? l10n.validationCurrentPassword
                          : null,
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _new,
                      label: l10n.newPasswordLabel,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (v) {
                        final value = v ?? '';
                        if (!AuthValidators.isValidPassword(value)) {
                          return l10n.validationPassword(
                            AuthValidators.minPasswordLength,
                          );
                        }
                        return value == _current.text
                            ? l10n.validationSamePassword
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _confirm,
                      label: l10n.confirmPasswordLabel,
                      autofillHints: const [AutofillHints.newPassword],
                      onSubmitted: _submit,
                      validator: (v) => v == _new.text
                          ? null
                          : l10n.validationPasswordsDiffer,
                    ),
                    if (state.hasError) ...[
                      const SizedBox(height: 16),
                      AuthErrorBanner(
                        message: failureMessage(l10n, state.error!),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: state.isLoading ? null : _submit,
                      child: state.isLoading
                          ? const InlineProgress()
                          : Text(l10n.changePasswordSubmit),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
