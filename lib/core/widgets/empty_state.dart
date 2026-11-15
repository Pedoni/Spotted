import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/squircle_avatar.dart';

/// Quando una lista è vuota: un'icona lampone in un quadrato arrotondato, un
/// titolo, un testo che dice cosa fare e, se serve, un pulsante.
///
/// Non occupa tutto lo spazio: dentro una pagina si mette al centro
/// (`Center`), dentro una lista di sezioni va com'è. Con [compact] è più
/// piccolo, per le sezioni di una pagina più lunga.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Di solito un `FilledButton` o un `OutlinedButton`.
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = compact ? 56.0 : 72.0;
    return Padding(
      padding: EdgeInsets.all(compact ? 16 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SquircleAvatar(
            background: scheme.primaryContainer,
            size: size,
            child: Icon(
              icon,
              size: size * 0.5,
              color: scheme.onPrimaryContainer,
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...[
            SizedBox(height: compact ? 12 : 20),
            action!,
          ],
        ],
      ),
    );
  }
}
