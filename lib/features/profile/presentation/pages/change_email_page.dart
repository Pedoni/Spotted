import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/auth/domain/auth_validators.dart';
import 'package:spotted/features/auth/presentation/providers/auth_controllers.dart';
import 'package:spotted/features/auth/presentation/providers/auth_providers.dart';
import 'package:spotted/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:spotted/features/auth/presentation/widgets/password_field.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Cambia l'email: il nuovo indirizzo e la password attuale. Supabase scrive
/// al nuovo indirizzo per la conferma; finché non è confermato resta valido
/// quello di adesso.
class ChangeEmailPage extends ConsumerStatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  ConsumerState<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends ConsumerState<ChangeEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final email = _email.text.trim();
    final sent = await ref
        .read(changeEmailControllerProvider.notifier)
        .submit(currentPassword: _password.text, newEmail: email);
    if (sent && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.emailConfirmationSent(email))),
      );
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(changeEmailControllerProvider);
    final currentEmail = ref.watch(authStateProvider).value?.email;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.changeEmail)),
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
                      l10n.changeEmailHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: l10n.newEmailLabel,
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (!AuthValidators.isValidEmail(value)) {
                          return l10n.validationEmail;
                        }
                        return value.toLowerCase() ==
                                currentEmail?.toLowerCase()
                            ? l10n.validationSameEmail
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _password,
                      label: l10n.currentPasswordLabel,
                      onSubmitted: _submit,
                      validator: (v) => (v ?? '').isEmpty
                          ? l10n.validationCurrentPassword
                          : null,
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
                          : Text(l10n.changeEmailSubmit),
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
