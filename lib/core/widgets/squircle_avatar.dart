import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotted/core/widgets/skeleton.dart';

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
    // Mentre carica è un riquadro neutro, non un colore della palette.
    if (isSkeleton(context)) {
      return Bone.square(
        size: size,
        borderRadius: BorderRadius.circular(size * 0.36),
      );
    }
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
