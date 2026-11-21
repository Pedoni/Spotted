import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/widgets/error_view.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';
import 'package:spotted/features/tags/domain/entities/tag.dart';
import 'package:spotted/features/tags/presentation/providers/tags_providers.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Il selettore dei tag di un canale: i tag raggruppati per categoria, da 1 a
/// 3 scelti. Raggiunto il massimo gli altri si disattivano finché non se ne
/// toglie uno.
class TagPicker extends ConsumerWidget {
  const TagPicker({
    required this.channelId,
    required this.selected,
    required this.onChanged,
    this.maxSelected = SpotValidators.maxTags,
    this.hint,
    super.key,
  });

  final String channelId;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  /// Quanti tag si possono scegliere al massimo; `null` senza limite (i
  /// filtri). Raggiunto il massimo gli altri si spengono.
  final int? maxSelected;

  /// Il testo sopra i tag. Se manca: "Scegli da 1 a 3 tag".
  final String? hint;

  void _toggle(String slug) {
    final next = List.of(selected);
    if (!next.remove(slug)) next.add(slug);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = channelTagsProvider(channelId);

    return ref
        .watch(provider)
        .when(
          loading: () => const Skeleton(child: _TagsPlaceholder()),
          error: (error, _) =>
              ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
          data: (tags) {
            final max = maxSelected;
            final full = max != null && selected.length >= max;
            // Le categorie nell'ordine in cui arrivano dal database.
            final categories = <String, List<Tag>>{};
            for (final tag in tags) {
              categories.putIfAbsent(tag.category, () => []).add(tag);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hint ??
                      l10n.tagsChooseHint(
                        SpotValidators.minTags,
                        SpotValidators.maxTags,
                      ),
                  style: theme.textTheme.bodySmall,
                ),
                for (final entry in categories.entries) ...[
                  const SizedBox(height: 16),
                  Text(entry.key, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final tag in entry.value)
                        FilterChip(
                          label: Text(tag.label),
                          selected: selected.contains(tag.slug),
                          onSelected: full && !selected.contains(tag.slug)
                              ? null
                              : (_) => _toggle(tag.slug),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        );
  }
}

/// Segnaposto mentre i tag si caricano.
class _TagsPlaceholder extends StatelessWidget {
  const _TagsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (var i = 0; i < 12; i++) Chip(label: Text('Tag numero $i')),
      ],
    );
  }
}
