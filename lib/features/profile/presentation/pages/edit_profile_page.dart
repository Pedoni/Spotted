import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/auth/domain/auth_validators.dart';
import 'package:spotted/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:spotted/features/profile/domain/profile_validators.dart';
import 'package:spotted/features/profile/presentation/providers/profile_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Modifica i propri dati: nome, cognome e data di nascita. Lo username si
/// vede ma non si cambia.
class EditProfilePage extends ConsumerWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editMyData)),
      body: profile.when(
        loading: () => const SkeletonScroll(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: _EditProfileForm(profile: _placeholder, skeleton: true),
          ),
        ),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: (profile) => _EditProfileForm(profile: profile),
      ),
    );
  }

  /// Dati finti per lo scheletro.
  static const _placeholder = Profile(
    id: 'skeleton',
    username: 'username',
    firstName: 'Nome',
    lastName: 'Cognome',
  );
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile, this.skeleton = false});

  final Profile profile;

  /// Disegnato come scheletro: niente da modificare.
  final bool skeleton;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.profile.firstName);
  late final _last = TextEditingController(text: widget.profile.lastName);
  late final _birth = TextEditingController();
  late DateTime? _birthDate = widget.profile.birthDate;

  @override
  void initState() {
    super.initState();
    // Il testo della data dipende dalla lingua: si scrive dopo il primo
    // disegno.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showBirthDate());
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _birth.dispose();
    super.dispose();
  }

  void _showBirthDate() {
    if (!mounted) return;
    final date = _birthDate;
    _birth.text = date == null
        ? ''
        : MaterialLocalizations.of(context).formatShortDate(date);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: ProfileValidators.earliestBirthDate,
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() => _birthDate = picked);
    _showBirthDate();
  }

  void _clearBirthDate() {
    setState(() => _birthDate = null);
    _showBirthDate();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final saved = await ref
        .read(editProfileControllerProvider.notifier)
        .submit(
          firstName: _first.text,
          lastName: _last.text,
          birthDate: _birthDate,
        );
    if (saved && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(editProfileControllerProvider);

    return SafeArea(
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
                    l10n.editMyDataHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  // Lo username si vede ma non si cambia.
                  TextFormField(
                    initialValue: widget.profile.username,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: l10n.usernameReadOnlyLabel,
                      prefixText: '@',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _first,
                    enabled: !widget.skeleton,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.givenName],
                    maxLength: AuthValidators.maxNameLength,
                    decoration: InputDecoration(
                      labelText: l10n.firstNameLabel,
                      counterText: '',
                    ),
                    validator: (v) => ProfileValidators.isValidName(v ?? '')
                        ? null
                        : l10n.validationRequired,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _last,
                    enabled: !widget.skeleton,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.familyName],
                    maxLength: AuthValidators.maxNameLength,
                    decoration: InputDecoration(
                      labelText: l10n.lastNameLabel,
                      counterText: '',
                    ),
                    validator: (v) => ProfileValidators.isValidName(v ?? '')
                        ? null
                        : l10n.validationRequired,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _birth,
                    readOnly: true,
                    enabled: !widget.skeleton,
                    onTap: () => unawaited(_pickBirthDate()),
                    decoration: InputDecoration(
                      labelText: l10n.birthDateLabel,
                      hintText: l10n.birthDateHint,
                      suffixIcon: _birthDate == null
                          ? const Icon(Icons.calendar_month_rounded)
                          : IconButton(
                              tooltip: l10n.clearBirthDate,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: _clearBirthDate,
                            ),
                    ),
                  ),
                  if (state.hasError) ...[
                    const SizedBox(height: 16),
                    AuthErrorBanner(
                      message: failureMessage(l10n, state.error!),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: state.isLoading || widget.skeleton
                        ? null
                        : _submit,
                    child: state.isLoading
                        ? const InlineProgress()
                        : Text(l10n.saveProfile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
