import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotted/core/widgets/brand_blobs.dart';
import 'package:spotted/core/widgets/skeleton.dart';

/// La copertina in cima a un canale. Finché il canale non ne sceglie una sua
/// ([imageUrl]), tutti i canali hanno la stessa, quella di marca: le macchie
/// lampone, gialla e indaco su inchiostro.
class ChannelCover extends StatelessWidget {
  const ChannelCover({this.imageUrl, this.height = defaultHeight, super.key});

  static const defaultHeight = 148.0;

  /// L'immagine scelta dal canale; se manca o non si carica c'è quella di
  /// default.
  final String? imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Mentre carica è un riquadro neutro, non i colori di marca.
    if (isSkeleton(context)) {
      return Bone(width: double.infinity, height: height, uniRadius: 0);
    }

    const fallback = BrandBlobs();
    final url = imageUrl;
    return ExcludeSemantics(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: url == null
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }
}
