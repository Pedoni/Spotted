import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';
import 'package:spotted/features/tags/presentation/providers/tags_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// La barra in cima alla scheda Spots: il campo di ricerca (sempre visibile),
/// il pulsante dei filtri per tag con il numero di tag scelti, e sotto i tag
/// scelti come chip che si tolgono con la "x".
class SpotsFilterBar extends ConsumerWidget {
  const SpotsFilterBar({
    required this.controller,
    required this.tags,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenTagFilter,
    required this.onRemoveTag,
    super.key,
  });

  final TextEditingController controller;

  /// I tag scelti (nomi tecnici).
  final List<String> tags;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenTagFilter;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final labels = ref.watch(tagLabelsProvider).value ?? const {};
    final text = controller.text.trim();
    // Con una sola lettera si ricorda che la ricerca parte da due.
    final tooShort =
        text.isNotEmpty && !SpotValidators.isSearchLongEnough(text);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: l10n.searchSpotsHint,
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded),
                    helperText: tooShort
                        ? l10n.searchSpotsMinChars(
                            SpotValidators.minSearchLength,
                          )
                        : null,
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.clearSearch,
                            icon: const Icon(Icons.close_rounded),
                            onPressed: onClearSearch,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge.count(
                count: tags.length,
                isLabelVisible: tags.isNotEmpty,
                child: IconButton.outlined(
                  tooltip: l10n.tagFilterTooltip,
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: onOpenTagFilter,
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final tag in tags)
                  InputChip(
                    label: Text(labels[tag] ?? tag),
                    onDeleted: () => onRemoveTag(tag),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
