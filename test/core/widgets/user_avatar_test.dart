import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/theme/app_theme.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/core/widgets/user_avatar.dart';

Widget host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets("con lo username mostra l'iniziale", (tester) async {
    await tester.pumpWidget(host(const UserAvatar(username: 'luigi')));

    expect(find.text('L'), findsOneWidget);
    expect(find.byType(ChannelAvatar), findsOneWidget);
    expect(find.byIcon(Icons.theater_comedy_outlined), findsNothing);
  });

  testWidgets('se è anonima mostra la maschera su indaco', (tester) async {
    await tester.pumpWidget(host(const UserAvatar()));

    expect(find.byIcon(Icons.theater_comedy_outlined), findsOneWidget);
    final icon = tester.widget<Icon>(
      find.byIcon(Icons.theater_comedy_outlined),
    );
    expect(icon.color, AppTheme.light.colorScheme.onSecondaryContainer);
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(UserAvatar),
        matching: find.byType(Container),
      ),
    );
    expect(
      (container.decoration! as ShapeDecoration).color,
      AppTheme.light.colorScheme.secondaryContainer,
    );
  });

  testWidgets('ha la dimensione richiesta', (tester) async {
    await tester.pumpWidget(host(const UserAvatar(size: 56)));

    expect(tester.getSize(find.byType(UserAvatar)), const Size(56, 56));
  });
}
