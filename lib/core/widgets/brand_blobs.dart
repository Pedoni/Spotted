import 'package:flutter/material.dart';
import 'package:spotted/core/theme/app_colors.dart';

/// Le macchie colorate del marchio: lampone in alto a destra, giallo in basso a
/// sinistra e indaco in basso a destra, su un fondo inchiostro. Come nella
/// splash: un momento di marca, uguale nel tema chiaro e in quello scuro.
///
/// Riempie lo spazio che gli viene dato; le macchie stanno agli angoli, al
/// centro resta libero per il logo.
class BrandBlobs extends StatelessWidget {
  const BrandBlobs({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: SizedBox.expand(child: CustomPaint(painter: BrandBlobsPainter())),
    );
  }
}

class BrandBlobsPainter extends CustomPainter {
  const BrandBlobsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.ink);

    // Lampone, in alto a destra.
    final raspberry = Path()
      ..moveTo(w * 0.56, 0)
      ..cubicTo(w * 0.62, h * 0.10, w * 0.78, h * 0.12, w * 0.88, h * 0.20)
      ..cubicTo(w * 0.96, h * 0.27, w * 0.99, h * 0.36, w, h * 0.44)
      ..lineTo(w, 0)
      ..close();
    // Giallo, in basso a sinistra.
    final yellow = Path()
      ..moveTo(0, h * 0.52)
      ..cubicTo(w * 0.12, h * 0.50, w * 0.22, h * 0.62, w * 0.30, h * 0.74)
      ..cubicTo(w * 0.36, h * 0.84, w * 0.40, h * 0.94, w * 0.44, h)
      ..lineTo(0, h)
      ..close();
    // Indaco, in basso a destra.
    final indigo = Path()
      ..moveTo(w, h * 0.58)
      ..cubicTo(w * 0.90, h * 0.60, w * 0.80, h * 0.72, w * 0.74, h * 0.82)
      ..cubicTo(w * 0.70, h * 0.90, w * 0.66, h * 0.96, w * 0.62, h)
      ..lineTo(w, h)
      ..close();

    void blob(Path path, Color from, Color to, Alignment begin, Alignment end) {
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: begin,
            end: end,
            colors: [from, to],
          ).createShader(path.getBounds()),
      );
    }

    // Una sfumatura leggera dentro la stessa tinta, mai un altro colore.
    blob(
      raspberry,
      AppColors.raspberryOnDark,
      AppColors.raspberry,
      Alignment.topLeft,
      Alignment.bottomRight,
    );
    blob(
      yellow,
      AppColors.highlight,
      AppColors.highlightDeep,
      Alignment.topRight,
      Alignment.bottomLeft,
    );
    blob(
      indigo,
      AppColors.indigoOnDark,
      AppColors.indigo,
      Alignment.topLeft,
      Alignment.bottomRight,
    );
  }

  @override
  bool shouldRepaint(BrandBlobsPainter oldDelegate) => false;
}
