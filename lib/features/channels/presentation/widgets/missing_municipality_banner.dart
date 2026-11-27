import 'package:flutter/material.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// L'invito al proprietario di un canale nato senza città (quando era
/// facoltativa): ora è obbligatoria, e modificando il canale va indicata.
/// Giallo, perché è un'avvertenza (l'evidenziatore dell'app).
class MissingMunicipalityBanner extends StatelessWidget {
  const MissingMunicipalityBanner({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: ShapeDecoration(
        color: scheme.tertiaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.place_rounded, color: scheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.missingMunicipalityTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.missingMunicipalityBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAdd,
            style: TextButton.styleFrom(
              foregroundColor: scheme.onTertiaryContainer,
            ),
            child: Text(l10n.missingMunicipalityAction),
          ),
        ],
      ),
    );
  }
}
