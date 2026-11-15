import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/highlighted_text.dart';

Widget host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

/// I pezzi di testo evidenziati, in ordine.
List<String> highlighted(WidgetTester tester) {
  final rich = tester.widget<RichText>(find.byType(RichText).first);
  final spans = <String>[];
  rich.text.visitChildren((span) {
    if (span is TextSpan && span.style?.backgroundColor != null) {
      spans.add(span.text!);
    }
    return true;
  });
  return spans;
}

void main() {
  group('matches', () {
    test('trova le parti uguali, con la posizione', () {
      final ranges = HighlightedText.matches('Ombrello perso', 'brell');

      expect(ranges, [const TextRange(start: 2, end: 7)]);
    });

    test('non distingue maiuscole', () {
      expect(
        HighlightedText.matches('OMBRELLO', 'ombrello'),
        [const TextRange(start: 0, end: 8)],
      );
      expect(
        HighlightedText.matches('ombrello', 'OMBRELLO'),
        [const TextRange(start: 0, end: 8)],
      );
    });

    test('non distingue accenti, in entrambi i sensi', () {
      expect(
        HighlightedText.matches('Perché non rispondi?', 'perche'),
        [const TextRange(start: 0, end: 6)],
      );
      expect(
        HighlightedText.matches('Perche non rispondi?', 'PERCHÉ'),
        [const TextRange(start: 0, end: 6)],
      );
      expect(
        HighlightedText.matches('Forlì e Cesena', 'forli'),
        [const TextRange(start: 0, end: 5)],
      );
    });

    test('trova più occorrenze, senza sovrapporle', () {
      expect(
        HighlightedText.matches('ciao ciao ciao', 'ciao'),
        [
          const TextRange(start: 0, end: 4),
          const TextRange(start: 5, end: 9),
          const TextRange(start: 10, end: 14),
        ],
      );
      expect(
        HighlightedText.matches('aaaa', 'aa'),
        [const TextRange(start: 0, end: 2), const TextRange(start: 2, end: 4)],
      );
    });

    test('il testo cercato è una sequenza unica, spazi compresi', () {
      expect(
        HighlightedText.matches('ombrello perso in aula', 'ello perso'),
        [const TextRange(start: 4, end: 14)],
      );
      expect(
        HighlightedText.matches('ombrello perso', 'perso ombrello'),
        isEmpty,
      );
    });

    test('gli spazi ai bordi del testo cercato non contano', () {
      expect(
        HighlightedText.matches('Ombrello', '  ombrello '),
        [const TextRange(start: 0, end: 8)],
      );
    });

    test('nessuna parte uguale: elenco vuoto', () {
      expect(HighlightedText.matches('Ombrello perso', 'zzz'), isEmpty);
    });

    test('senza testo cercato non evidenzia niente', () {
      expect(HighlightedText.matches('Ombrello', null), isEmpty);
      expect(HighlightedText.matches('Ombrello', ''), isEmpty);
      expect(HighlightedText.matches('Ombrello', '   '), isEmpty);
    });

    test('i simboli speciali valgono come lettere', () {
      expect(
        HighlightedText.matches('Sconto del 100% oggi', '100%'),
        [const TextRange(start: 11, end: 15)],
      );
      expect(
        HighlightedText.matches('cartella a_b', '_'),
        [const TextRange(start: 10, end: 11)],
      );
      expect(HighlightedText.matches('a.b', '.'), [
        const TextRange(start: 1, end: 2),
      ]);
      expect(HighlightedText.matches('(prova)', '(p'), [
        const TextRange(start: 0, end: 2),
      ]);
    });

    test('le posizioni valgono per il testo originale, con gli accenti', () {
      const text = 'Perché è già tardi';
      final range = HighlightedText.matches(text, 'gia').single;

      expect(text.substring(range.start, range.end), 'già');
    });

    test('fold toglie maiuscole e accenti lettera per lettera', () {
      expect(HighlightedText.fold('ÀÈÌÒÙ àèìòù'), 'aeiou aeiou');
      expect(HighlightedText.fold('Ça va, ñandú'), 'ca va, nandu');
      expect(HighlightedText.fold('Perché').length, 'Perché'.length);
    });
  });

  group('widget', () {
    testWidgets('senza testo cercato è un Text normale', (tester) async {
      await tester.pumpWidget(host(const HighlightedText('Ombrello perso')));

      expect(find.text('Ombrello perso'), findsOneWidget);
    });

    testWidgets('senza risultati è un Text normale', (tester) async {
      await tester.pumpWidget(
        host(const HighlightedText('Ombrello perso', query: 'zzz')),
      );

      expect(find.text('Ombrello perso'), findsOneWidget);
    });

    testWidgets('evidenzia le parti trovate e lascia le altre', (tester) async {
      await tester.pumpWidget(
        host(const HighlightedText('Ombrello perso', query: 'brell')),
      );

      expect(highlighted(tester), ['brell']);
      // Il testo intero c'è ancora, in pezzi.
      expect(
        find.textContaining('Ombrello perso', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('evidenzia tutte le occorrenze, anche con accenti', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const HighlightedText('Perché? Perche no!', query: 'PERCHE')),
      );

      expect(highlighted(tester), ['Perché', 'Perche']);
    });

    testWidgets('l evidenziazione è gialla, con testo scuro', (tester) async {
      await tester.pumpWidget(
        host(const HighlightedText('Ombrello', query: 'ombr')),
      );

      final scheme = AppTheme.light.colorScheme;
      final rich = tester.widget<RichText>(find.byType(RichText).first);
      TextStyle? style;
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.style?.backgroundColor != null) {
          style = span.style;
        }
        return true;
      });
      expect(style!.backgroundColor, scheme.tertiaryContainer);
      expect(style!.color, scheme.onTertiaryContainer);
    });

    testWidgets('mantiene lo stile del testo', (tester) async {
      const style = TextStyle(fontSize: 22);
      await tester.pumpWidget(
        host(const HighlightedText('Ombrello', query: 'ombr', style: style)),
      );

      final rich = tester.widget<RichText>(find.byType(RichText).first);
      final inner = (rich.text as TextSpan).children!.single as TextSpan;
      expect(inner.style!.fontSize, 22);
    });

    testWidgets('un testo che finisce con la parte trovata non perde pezzi', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const HighlightedText('Ombrello', query: 'ello')),
      );

      expect(highlighted(tester), ['ello']);
      expect(
        find.textContaining('Ombrello', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
