import 'package:flutter/material.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';
import 'package:spotted/features/tags/presentation/widgets/tag_picker.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Apre il foglio con cui il proprietario sceglie i tag (da 1 a 3) di uno spot
/// che sta per pubblicare. Restituisce i tag scelti, o `null` se lo chiude.
Future<List<String>?> showApproveSpotSheet(
  BuildContext context, {
  required String channelId,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ApproveSpotSheet(channelId: channelId),
  );
}

class _ApproveSpotSheet extends StatefulWidget {
  const _ApproveSpotSheet({required this.channelId});

  final String channelId;

  @override
  State<_ApproveSpotSheet> createState() => _ApproveSpotSheetState();
}

class _ApproveSpotSheetState extends State<_ApproveSpotSheet> {
  var _tags = <String>[];

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
                      l10n.approveSpotTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TagPicker(
                      channelId: widget.channelId,
                      selected: _tags,
                      onChanged: (tags) => setState(() => _tags = tags),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: SpotValidators.isValidTagCount(_tags.length)
                      ? () => Navigator.of(context).pop(_tags)
                      : null,
                  child: Text(l10n.approveSpotAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
