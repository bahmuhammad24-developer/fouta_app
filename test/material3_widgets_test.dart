import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/theme/fouta_theme_diaspora.dart';
import 'package:fouta_app/widgets/fouta_button.dart';
import 'package:fouta_app/widgets/fouta_card.dart';

void main() {
  testWidgets('FoutaButton uses color scheme under Material 3',
      (WidgetTester tester) async {
    final ThemeData theme = FoutaThemeDiaspora.lightTheme;

    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        body: FoutaButton(label: 'Press', onPressed: () {}),
      ),
    ));

    final ElevatedButton button =
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    final Color? background = button.style?.backgroundColor?.resolve({});

    expect(background, theme.colorScheme.secondary);
  });

  testWidgets('FoutaCard uses card color under Material 3',
      (WidgetTester tester) async {
    final ThemeData theme = FoutaThemeDiaspora.lightTheme;

    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: FoutaCard(child: Text('Card')),
      ),
    ));

    final containerFinder = find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final decoration = widget.decoration;
      return decoration is BoxDecoration && decoration.color == theme.cardColor;
    });

    final Container container = tester.widget<Container>(containerFinder);
    final BoxDecoration decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, theme.cardColor);
  });
}

