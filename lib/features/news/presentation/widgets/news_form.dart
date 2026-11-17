import 'package:flutter/material.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/news/domain/news_validators.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Il modulo di una news (titolo e testo), uguale per crearla e modificarla.
/// Chi lo usa decide cosa fare con i valori ([onSubmit]) e mostra lo stato
/// ([busy], [error]).
class NewsForm extends StatefulWidget {
  const NewsForm({
    required this.submitLabel,
    required this.onSubmit,
    this.initialTitle = '',
    this.initialBody = '',
    this.channelName,
    this.busy = false,
    this.error,
    super.key,
  });

  final String submitLabel;
  final void Function(String title, String body) onSubmit;
  final String initialTitle;
  final String initialBody;

  /// Il canale a cui appartiene la news, mostrato sopra il modulo.
  final String? channelName;
  final bool busy;
  final Object? error;

  @override
  State<NewsForm> createState() => _NewsFormState();
}

class _NewsFormState extends State<NewsForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initialTitle);
  late final _body = TextEditingController(text: widget.initialBody);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(_title.text, _body.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.channelName != null) ...[
            Text(widget.channelName!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
          ],
          Text(l10n.newsPublicNote, style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          TextFormField(
            controller: _title,
            maxLength: NewsValidators.maxTitleLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.newsTitleLabel),
            validator: (v) => NewsValidators.isValidTitle(v ?? '')
                ? null
                : l10n.validationRequired,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _body,
            minLines: 5,
            maxLines: 12,
            maxLength: NewsValidators.maxBodyLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.newsBodyLabel,
              alignLabelWithHint: true,
            ),
            validator: (v) => NewsValidators.isValidBody(v ?? '')
                ? null
                : l10n.validationRequired,
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 16),
            Text(
              failureMessage(l10n, widget.error!),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.busy ? null : _submit,
            child: widget.busy
                ? const InlineProgress()
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
