import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/stories/stories_tray.dart';

void main() {
  testWidgets('shows Your Story tile when onAdd provided', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: StoriesTray(
        currentUserId: 'u1',
        onAdd: _dummy,
      ),
    ));
    expect(find.text('Your Story'), findsOneWidget);
  });
}

void _dummy() {}
