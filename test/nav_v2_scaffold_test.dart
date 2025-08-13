import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/navigation/nav_v2_scaffold.dart';

void main() {
  testWidgets('switches tabs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NavV2Scaffold()));
    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
    expect(find.text('Shorts'), findsOneWidget);
  });
}
