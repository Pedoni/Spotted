import 'package:flutter/material.dart';
import 'package:spotted/features/tags/presentation/widgets/tag_picker.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Apre il foglio con cui si filtrano gli spot di un canale per tag: tutti i
/// tag del canale per categoria, senza limite di scelta. Restituisce i tag
/// scelti (premendo "Applica" o "Azzera"), o `null` se lo si chiude senza
/// scegliere.
Future<List<String>?> showTagFilterSheet(
  BuildContext context, {
  required String channelId,
  required List<String> selected,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        _TagFilterSheet(channelId: channelId, initial: selected),
  );
}

class _TagFilterSheet extends StatefulWidget {
  const _TagFilterSheet({required this.channelId, required this.initial});

  final String channelId;
  final List<String> initial;

  @override
  State<_TagFilterSheet> createState() => _TagFilterSheetState();
}

class _TagFilterSheetState extends State<_TagFilterSheet> {
  late List<String> _tags = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tagFilterTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TagPicker(
                      channelId: widget.channelId,
                      selected: _tags,
                      maxSelected: null,
                      hint: l10n.tagFilterHint,
                      onChanged: (tags) => setState(() => _tags = tags),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(<String>[]),
                      child: Text(l10n.filtersReset),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_tags),
                      child: Text(l10n.filtersApply),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
