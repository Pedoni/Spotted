import 'package:flutter/material.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Cuore con il numero di "mi piace". Toccandolo si mette o si toglie.
class LikeButton extends StatelessWidget {
  const LikeButton({
    required this.liked,
    required this.count,
    required this.onPressed,
    super.key,
  });

  final bool liked;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      toggled: liked,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          liked ? Icons.favorite : Icons.favorite_border,
          size: 20,
          color: liked ? colors.error : null,
          semanticLabel: liked ? l10n.unlike : l10n.like,
        ),
        label: Text('$count'),
      ),
    );
  }
}
