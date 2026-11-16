import 'package:flutter/material.dart';

/// Il pulsante con la matita sull'angolo di un'immagine del canale, visibile
/// solo al proprietario. Piccolo, lampone (è un'azione), con un bordo del
/// colore dello sfondo per staccarsi dall'immagine.
class ChannelImageEditButton extends StatelessWidget {
  const ChannelImageEditButton({
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  static const size = 32.0;

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: scheme.primary,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scheme.surface, width: 3),
          ),
          child: InkWell(
            customBorder: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Icon(
                Icons.edit_rounded,
                size: 16,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
