import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_colors.dart';
import 'package:spotted/core/widgets/radar_logo.dart';

Widget host(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

/// L'oggetto che disegna il logo.
RenderCustomPaint paintOf(WidgetTester tester) {
  return tester.renderObject<RenderCustomPaint>(
    find.descendant(
      of: find.byType(RadarLogo),
      matching: find.byType(CustomPaint),
    ),
  );
}

void main() {
  testWidgets('ha la dimensione richiesta, quadrata', (tester) async {
    await tester.pumpWidget(host(const RadarLogo(size: 120)));

    expect(tester.getSize(find.byType(RadarLogo)), const Size(120, 120));
  });

  testWidgets('disegna lo spicchio, i due anelli, i tre puntini e il centro', (
    tester,
  ) async {
    // A 1024 pixel le misure sono quelle dell'SVG del marchio.
    await tester.pumpWidget(host(const RadarLogo(size: 1024, animate: false)));

    expect(
      paintOf(tester),
      paints
        ..path(color: AppColors.highlight)
        ..circle(
          x: 512,
          y: 512,
          radius: 350,
          color: AppColors.cream,
          strokeWidth: 30,
          style: PaintingStyle.stroke,
        )
        ..circle(
          x: 512,
          y: 512,
          radius: 205,
          color: AppColors.cream,
          strokeWidth: 30,
          style: PaintingStyle.stroke,
        )
        ..circle(x: 285, y: 312, radius: 40, color: AppColors.raspberry)
        ..circle(x: 704, y: 644, radius: 40, color: AppColors.indigo)
        ..circle(x: 330, y: 720, radius: 40, color: AppColors.highlight)
        ..circle(x: 512, y: 512, radius: 55, color: AppColors.highlight),
    );
  });

  testWidgets('si adatta alla dimensione: il disegno viene scalato', (
    tester,
  ) async {
    await tester.pumpWidget(host(const RadarLogo(size: 512, animate: false)));

    // La tela è da 1024: a 512 si disegna a metà scala.
    expect(
      paintOf(tester),
      paints
        ..save()
        ..scale(x: 0.5, y: 0.5),
    );
  });

  testWidgets('lo spicchio ruota una volta fino alla sua posizione', (
    tester,
  ) async {
    await tester.pumpWidget(host(const RadarLogo()));

    // All'inizio lo spicchio è spostato.
    final start = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(RadarLogo),
        matching: find.byType(CustomPaint),
      ),
    );
    expect((start.painter! as RadarLogoPainter).sweepOffset, isNot(0));

    await tester.pumpAndSettle();

    final end = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(RadarLogo),
        matching: find.byType(CustomPaint),
      ),
    );
    expect((end.painter! as RadarLogoPainter).sweepOffset, 0);
  });

  testWidgets('senza animazione sta subito fermo', (tester) async {
    await tester.pumpWidget(host(const RadarLogo(animate: false)));

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(RadarLogo),
        matching: find.byType(CustomPaint),
      ),
    );
    expect((paint.painter! as RadarLogoPainter).sweepOffset, 0);
  });

  testWidgets('se il sistema riduce le animazioni sta fermo', (tester) async {
    await tester.pumpWidget(
      host(const RadarLogo(), disableAnimations: true),
    );

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(RadarLogo),
        matching: find.byType(CustomPaint),
      ),
    );
    expect((paint.painter! as RadarLogoPainter).sweepOffset, 0);
  });

  testWidgets('è decorativo: non compare per i lettori di schermo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const RadarLogo()));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(RadarLogo),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
    handle.dispose();
  });

  test('si ridisegna solo se lo spicchio si sposta', () {
    const a = RadarLogoPainter();
    expect(a.shouldRepaint(const RadarLogoPainter()), isFalse);
    expect(a.shouldRepaint(const RadarLogoPainter(sweepOffset: 0.5)), isTrue);
  });
}
