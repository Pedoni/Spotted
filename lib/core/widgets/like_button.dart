import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Cuore con il numero di "mi piace". Toccandolo si mette o si toglie; quando
/// si mette fa un piccolo rimbalzo.
class LikeButton extends StatefulWidget {
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
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// 1 → 1,35 → 1: il rimbalzo.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.35,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.35,
        end: 1,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo quando il like viene messo, non quando viene tolto.
    if (widget.liked && !oldWidget.liked) unawaited(_bounce());
  }

  /// Il rimbalzo del cuore. È un metodo `async` per non dipendere da come le
  /// diverse versioni di Flutter annotano `forward` (l'analisi darebbe un
  /// avviso o con `unawaited` o senza).
  Future<void> _bounce() async {
    await _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      toggled: widget.liked,
      child: TextButton.icon(
        onPressed: widget.onPressed,
        icon: ScaleTransition(
          scale: _scale,
          child: Icon(
            widget.liked ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: widget.liked ? colors.primary : null,
            semanticLabel: widget.liked ? l10n.unlike : l10n.like,
          ),
        ),
        label: Text('${widget.count}'),
      ),
    );
  }
}
