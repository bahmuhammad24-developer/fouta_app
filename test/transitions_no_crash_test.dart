import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/navigation/transitions.dart';

void main() {
  testWidgets('pushFromRight navigates without crashing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              FoutaTransitions.pushFromRight(const Scaffold(body: Text('detail'))),
            );
          },
          child: const Text('go'),
        ),
      ),
    ));

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('detail'), findsOneWidget);
  });
}
