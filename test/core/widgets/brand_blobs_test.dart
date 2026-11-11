import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_colors.dart';
import 'package:spotted/core/widgets/brand_blobs.dart';

void main() {
  testWidgets('riempie lo spazio dato', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(width: 300, height: 200, child: BrandBlobs()),
        ),
      ),
    );

    expect(tester.getSize(find.byType(BrandBlobs)), const Size(300, 200));
  });

  testWidgets('disegna il fondo inchiostro e le tre macchie', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(width: 300, height: 200, child: BrandBlobs()),
        ),
      ),
    );

    final render = tester.renderObject<RenderCustomPaint>(
      find.descendant(
        of: find.byType(BrandBlobs),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(
      render,
      paints
        ..rect(rect: const Rect.fromLTWH(0, 0, 300, 200), color: AppColors.ink)
        ..path()
        ..path()
        ..path(),
    );
  });

  testWidgets('le tre macchie stanno agli angoli e il centro resta libero', (
    tester,
  ) async {
    // Le macchie si ricavano dai tre percorsi: nessuna copre il centro.
    const size = Size(400, 300);
    final recorder = PictureRecorderCanvas();
    const BrandBlobsPainter().paint(recorder.canvas, size);

    expect(recorder.paths, hasLength(3));
    for (final bounds in recorder.paths) {
      expect(
        bounds.contains(Offset(size.width / 2, size.height * 0.25)),
        isFalse,
        reason: 'il logo sta al centro in alto',
      );
    }
  });

  testWidgets('è decorativo e non si ridisegna', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 100, height: 100, child: BrandBlobs()),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(BrandBlobs),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
    expect(
      const BrandBlobsPainter().shouldRepaint(const BrandBlobsPainter()),
      isFalse,
    );
  });
}

/// Un [Canvas] che registra i bordi dei percorsi disegnati.
class PictureRecorderCanvas {
  PictureRecorderCanvas() {
    canvas = _RecordingCanvas(this);
  }

  late final Canvas canvas;
  final paths = <Rect>[];
}

class _RecordingCanvas implements Canvas {
  _RecordingCanvas(this._owner);

  final PictureRecorderCanvas _owner;

  @override
  void drawPath(Path path, Paint paint) => _owner.paths.add(path.getBounds());

  @override
  void drawRect(Rect rect, Paint paint) {}

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
