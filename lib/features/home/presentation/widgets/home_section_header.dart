import 'package:flutter/material.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Il titolo di una sezione della Home, con la freccia che porta all'elenco
/// completo. Senza [onTap] la freccia non c'è (non c'è niente da vedere).
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({required this.title, this.onTap, super.key});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (onTap != null)
            IconButton(
              tooltip: l10n.viewAll,
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: onTap,
            )
          else
            const SizedBox(height: 48),
        ],
      ),
    );
  }
}
