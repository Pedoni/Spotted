import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/features/tags/presentation/providers/tags_providers.dart';

/// I tag di uno spot, uno accanto all'altro. Se il nome visibile non è ancora
/// arrivato (o non si carica) si mostra il nome tecnico: meglio un tag meno
/// bello che nessun tag. Senza tag non occupa spazio.
class SpotTagChips extends ConsumerWidget {
  const SpotTagChips({required this.tags, super.key});

  final List<String> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final labels = ref.watch(tagLabelsProvider).value ?? const {};
    final theme = Theme.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          DecoratedBox(
            decoration: ShapeDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: const StadiumBorder(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                labels[tag] ?? tag,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
