import 'package:flutter/material.dart';

/// Quadrato dagli angoli molto arrotondati (squircle) con un contenuto al
/// centro: la base degli avatar di canali e persone.
class SquircleAvatar extends StatelessWidget {
  const SquircleAvatar({
    required this.background,
    required this.child,
    this.size = 44,
    super.key,
  });

  final Color background;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: background,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(size * 0.36),
          ),
        ),
        child: child,
      ),
    );
  }
}
