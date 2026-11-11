import 'package:flutter/material.dart';

/// Piccolo indicatore di avanzamento dentro un pulsante o un campo mentre si
/// invia qualcosa. Non è un caricamento di contenuto: per quelli si usa
/// `Skeleton`.
class InlineProgress extends StatelessWidget {
  const InlineProgress({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
