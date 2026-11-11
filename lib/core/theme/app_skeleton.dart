import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Aspetto degli scheletri di caricamento: uno shimmer morbido nei toni della
/// superficie (crema nel tema chiaro, viola scuro nello scuro), senza colori
/// accesi che farebbero concorrenza ai contenuti.
abstract final class AppSkeleton {
  static SkeletonizerConfigData config(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final base = scheme.surfaceContainerHighest;
    final highlight = dark
        ? Color.lerp(base, scheme.onSurface, 0.14)!
        : Color.lerp(base, scheme.surfaceContainerLowest, 0.45)!;
    return SkeletonizerConfigData(
      brightness: scheme.brightness,
      effectResolver: (_) => ShimmerEffect(
        baseColor: base,
        highlightColor: highlight,
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }
}
