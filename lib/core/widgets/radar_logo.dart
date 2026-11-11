import 'package:flutter/material.dart';
import 'package:spotted/core/theme/app_colors.dart';

/// Il logo di Spotted: un radar con due anelli, uno spicchio e tre puntini,
/// uno per colore di marca. Le proporzioni sono quelle dell'icona
/// (`design/brand`, tela da 1024). Pensato per lo sfondo inchiostro: gli anelli
/// sono color crema.
///
/// Con [animate] lo spicchio ruota una volta fino alla sua posizione, come un
/// radar che scansiona; se il sistema chiede di ridurre le animazioni sta
/// fermo.
class RadarLogo extends StatelessWidget {
  const RadarLogo({this.size = 96, this.animate = true, super.key});

  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final still = !animate || MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: still ? 0 : -1.4, end: 0),
        duration: still ? Duration.zero : const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, sweepOffset, _) => CustomPaint(
          size: Size.square(size),
          painter: RadarLogoPainter(sweepOffset: sweepOffset),
        ),
      ),
    );
  }
}

/// Disegna il logo. [sweepOffset] (in radianti) sposta lo spicchio rispetto
/// alla sua posizione finale.
class RadarLogoPainter extends CustomPainter {
  const RadarLogoPainter({this.sweepOffset = 0});

  final double sweepOffset;

  static const _canvas = 1024.0;
  static const _center = Offset(512, 512);

  @override
  void paint(Canvas canvas, Size size) {
    // Lo spicchio: dal centro, tra due raggi, chiuso da un arco di raggio 384.
    canvas
      ..save()
      ..scale(size.width / _canvas, size.height / _canvas)
      ..save()
      ..translate(_center.dx, _center.dy)
      ..rotate(sweepOffset)
      ..translate(-_center.dx, -_center.dy)
      ..drawPath(
        Path()
          ..moveTo(512, 512)
          ..lineTo(704.5, 179.8)
          ..arcToPoint(
            const Offset(820.5, 320),
            radius: const Radius.circular(384),
          )
          ..close(),
        Paint()..color = AppColors.highlight,
      )
      ..restore();

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..color = AppColors.cream;
    canvas
      ..drawCircle(_center, 350, ring)
      ..drawCircle(_center, 205, ring)
      ..drawCircle(
        const Offset(285, 312),
        40,
        Paint()..color = AppColors.raspberry,
      )
      ..drawCircle(
        const Offset(704, 644),
        40,
        Paint()..color = AppColors.indigo,
      )
      ..drawCircle(
        const Offset(330, 720),
        40,
        Paint()..color = AppColors.highlight,
      )
      ..drawCircle(_center, 55, Paint()..color = AppColors.highlight)
      ..restore();
  }

  @override
  bool shouldRepaint(RadarLogoPainter oldDelegate) {
    return oldDelegate.sweepOffset != sweepOffset;
  }
}
