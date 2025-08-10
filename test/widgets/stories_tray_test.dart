import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/widgets/stories/stories_tray.dart';

void main() {
  testWidgets('StoriesTray shows Your Story and triggers onAdd', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => StoriesTray(
          currentUserId: 'u1',
          onAdd: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const Placeholder(key: Key('camera'))),
            );
          },
        ),
      ),
    ));

    expect(find.text('Your Story'), findsOneWidget);

    await tester.tap(find.text('Your Story'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('camera')), findsOneWidget);
  });
}

