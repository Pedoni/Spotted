import 'dart:math';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotted/core/widgets/brand_blobs.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/channels/domain/entities/channel_image_kind.dart';

/// La copertina in cima a un canale. Finché il canale non ne ha una sua
/// ([imageUrl]), tutti hanno la stessa, quella di marca: le macchie lampone,
/// gialla e indaco su inchiostro.
///
/// Ha la stessa proporzione dell'immagine salvata (8:3), quindi su un telefono
/// si vede tutta; sugli schermi larghi non diventa altissima ([maxHeight]) e
/// l'immagine si adatta tagliando un po' sopra e sotto.
class ChannelCover extends StatelessWidget {
  const ChannelCover({this.imageUrl, this.height, super.key});

  /// L'altezza massima, per non coprire mezzo schermo su tablet e computer.
  static const maxHeight = 220.0;

  /// L'immagine scelta dal canale; se manca o non si carica c'è quella di
  /// default.
  final String? imageUrl;

  /// Un'altezza fissa; di default segue la proporzione dell'immagine.
  final double? height;

  /// L'altezza per una copertina larga [width].
  static double heightFor(double width) =>
      min(width / ChannelImageKind.cover.aspectRatio, maxHeight);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cover = height ?? heightFor(width);

        // Mentre carica è un riquadro neutro, non i colori di marca.
        if (isSkeleton(context)) {
          return Bone(width: double.infinity, height: cover, uniRadius: 0);
        }

        const fallback = BrandBlobs();
        final url = imageUrl;
        return ExcludeSemantics(
          child: SizedBox(
            width: double.infinity,
            height: cover,
            child: url == null
                ? fallback
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => fallback,
                  ),
          ),
        );
      },
    );
  }
}
