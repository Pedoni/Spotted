import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/chat/presentation/widgets/message_bubble.dart';
import 'package:spotted/l10n/app_localizations.dart';

import '../../../helpers/fake_repositories.dart';

Widget host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

/// Il fumetto (il riquadro colorato) del messaggio.
Finder bubble() => find.descendant(
  of: find.byType(MessageBubble),
  matching: find.byType(Container),
);

BoxDecoration decorationOf(WidgetTester tester) {
  return tester.widget<Container>(bubble()).decoration! as BoxDecoration;
}

/// Uno schermo di 400 pixel logici (senza il rapporto di pixel del test).
void narrowScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(400, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('un messaggio corto ha un fumetto stretto, non largo 80%', (
    tester,
  ) async {
    narrowScreen(tester);
    await tester.pumpWidget(
      host(MessageBubble(message: makeMessage(1, content: 'Ciao'))),
    );

    expect(tester.getSize(bubble()).width, lessThan(400 * 0.4));
  });

  testWidgets('un messaggio lungo non supera l 80% dello schermo', (
    tester,
  ) async {
    narrowScreen(tester);
    await tester.pumpWidget(
      host(MessageBubble(message: makeMessage(1, content: 'parola ' * 12))),
    );

    // 80% dello schermo, più i margini laterali del fumetto.
    expect(tester.getSize(bubble()).width, lessThanOrEqualTo(400 * 0.8));
  });

  testWidgets('i messaggi miei stanno a destra, quelli dell altro a sinistra', (
    tester,
  ) async {
    narrowScreen(tester);
    await tester.pumpWidget(
      host(
        MessageBubble(message: makeMessage(1, content: 'Ciao', isMine: true)),
      ),
    );
    expect(tester.getTopRight(bubble()).dx, greaterThan(400 - 20));

    await tester.pumpWidget(
      host(MessageBubble(message: makeMessage(1, content: 'Ciao'))),
    );
    expect(tester.getTopLeft(bubble()).dx, lessThan(20));
  });

  testWidgets('la coda del fumetto è dalla parte di chi scrive', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(MessageBubble(message: makeMessage(1, isMine: true))),
    );
    expect(
      decorationOf(tester).borderRadius,
      AppShapes.messageRadius(mine: true),
    );

    await tester.pumpWidget(host(MessageBubble(message: makeMessage(1))));
    expect(
      decorationOf(tester).borderRadius,
      AppShapes.messageRadius(mine: false),
    );
  });

  testWidgets('i miei sono lampone chiaro, quelli dell altro neutri', (
    tester,
  ) async {
    final scheme = AppTheme.light.colorScheme;
    await tester.pumpWidget(
      host(MessageBubble(message: makeMessage(1, isMine: true))),
    );
    expect(decorationOf(tester).color, scheme.primaryContainer);

    await tester.pumpWidget(host(MessageBubble(message: makeMessage(1))));
    expect(decorationOf(tester).color, scheme.surfaceContainerHigh);
  });

  testWidgets('nello scheletro anche i miei sono neutri', (tester) async {
    await tester.pumpWidget(
      host(
        Skeleton(child: MessageBubble(message: makeMessage(1, isMine: true))),
      ),
    );

    expect(
      decorationOf(tester).color,
      AppTheme.light.colorScheme.surfaceContainerHigh,
    );
  });

  testWidgets("mostra il testo e l'ora", (tester) async {
    await tester.pumpWidget(
      host(MessageBubble(message: makeMessage(1, content: 'Ciao a tutti'))),
    );

    expect(find.text('Ciao a tutti'), findsOneWidget);
    expect(find.textContaining(':'), findsOneWidget);
  });
}
